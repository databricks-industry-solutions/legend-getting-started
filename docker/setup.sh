#!/bin/bash

PWD="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
BUILD_DIR=$PWD/dist

##########################################
# Find public IP
##########################################

if [ -z "$HOST_DNS_NAME" ]; then
  echo "HOST_DNS_NAME is not specified, checking public IP"
  HOST_DNS_NAME=`curl http://checkip.amazonaws.com 2>/dev/null`
else
  HOST_DNS_NAME='127.0.0.1'
fi

##########################################
# Parse config file
##########################################

PROPERTIES=$PWD/config/config.properties
GITLAB_OAUTH_CLIENT=$(echo $(grep -v '^#' $PROPERTIES | grep -e "GITLAB_OAUTH_CLIENT" | gsed -e 's/.*=//'))
if [ -z "$GITLAB_OAUTH_CLIENT" ]; then
  echo "GITLAB_OAUTH_CLIENT is not specified."
  exit 1
fi

GITLAB_OAUTH_SECRET=$(echo $(grep -v '^#' $PROPERTIES | grep -e "GITLAB_OAUTH_SECRET" | gsed -e 's/.*=//'))
if [ -z "$GITLAB_OAUTH_SECRET" ]; then
  echo "GITLAB_OAUTH_SECRET is not specified."
  exit 1
fi

##########################################
# Clean up and prepare build directory
##########################################

[ -e $BUILD_DIR ] && rm -r $BUILD_DIR
mkdir -p $BUILD_DIR
mkdir -p $BUILD_DIR/data

##########################################
# create environment file
##########################################

DOTENV_FILE=$BUILD_DIR/.env
[ -e $DOTENV_FILE ] && rm $DOTENV_FILE
echo BUILD_DIR=$BUILD_DIR >> $DOTENV_FILE
cat $PWD/src/.env >> $DOTENV_FILE

##########################################
# Build all URLs
##########################################

source $PWD/src/.env
LEGEND_SDLC_PUBLIC_URL=http://$HOST_DNS_NAME:$LEGEND_SDLC_PORT
LEGEND_ENGINE_PUBLIC_URL=http://$HOST_DNS_NAME:$LEGEND_ENGINE_PORT
LEGEND_STUDIO_PUBLIC_URL=http://$HOST_DNS_NAME:$LEGEND_STUDIO_PORT

##########################################
# Copy over configs and scripts
##########################################

cp -r $PWD/src/scripts $BUILD_DIR/scripts
cp -r $PWD/src/configs $BUILD_DIR/configs
cp -r $PWD/config/vault.properties $BUILD_DIR/configs/engine/vault.properties

##########################################
# Configure configs
##########################################

for f in $(find $BUILD_DIR/configs -type f); do
  gsed -i 's/__GITLAB_OAUTH_CLIENT__/'$GITLAB_OAUTH_CLIENT'/g' $f
  gsed -i 's/__GITLAB_OAUTH_SECRET__/'$GITLAB_OAUTH_SECRET'/g' $f
  gsed -i 's/__HOST_DNS_NAME__/'$HOST_DNS_NAME'/g' $f
  gsed -i 's/__LEGEND_SDLC_PORT__/'$LEGEND_SDLC_PORT'/g' $f
  gsed -i 's~__LEGEND_SDLC_PUBLIC_URL__~'$LEGEND_SDLC_PUBLIC_URL'~g' $f
  gsed -i 's/__LEGEND_ENGINE_PORT__/'$LEGEND_ENGINE_PORT'/g' $f
  gsed -i 's~__LEGEND_ENGINE_URL__~'$LEGEND_ENGINE_PUBLIC_URL'~g' $f
  gsed -i 's/__LEGEND_STUDIO_PORT__/'$LEGEND_STUDIO_PORT'/g' $f
  gsed -i 's~__LEGEND_SDLC_URL__~'$LEGEND_SDLC_PUBLIC_URL'~g' $f
done

##########################################
# Print OAuth Redirect URIs
##########################################

echo ""
echo "Make sure to setup your Gitlab OAuth application to use the following redirect URIs:"
echo ""
echo "$LEGEND_ENGINE_PUBLIC_URL/callback"
echo "$LEGEND_SDLC_PUBLIC_URL/api/auth/callback"
echo "$LEGEND_SDLC_PUBLIC_URL/api/pac4j/login/callback"
echo "$LEGEND_STUDIO_PUBLIC_URL/studio/log.in/callback"