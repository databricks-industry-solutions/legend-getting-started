#!/usr/bin/env sh

PWD="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
BUILD_DIR=$PWD/dist

##########################################
# Parse config file
##########################################

PROPERTIES=$PWD/config.properties
GITLAB_OAUTH_CLIENT=$(echo $(grep -v '^#' $PROPERTIES | grep -e "GITLAB_OAUTH_CLIENT" | sed -e 's/.*=//'))
if [ -z "$GITLAB_OAUTH_CLIENT" ]; then
  echo "GITLAB_OAUTH_CLIENT is not specified."
  exit 1
fi

GITLAB_OAUTH_SECRET=$(echo $(grep -v '^#' $PROPERTIES | grep -e "GITLAB_OAUTH_SECRET" | sed -e 's/.*=//'))
if [ -z "$GITLAB_OAUTH_SECRET" ]; then
  echo "GITLAB_OAUTH_SECRET is not specified."
  exit 1
fi

##########################################
# 	Generate Mongo password
##########################################

MONGO_PASSWORD=$(openssl rand -base64 8 | sed 's:/::g' | awk -F "=" '{print $1}')

##########################################
# Find public IP
##########################################

HOST_DNS_NAME=$(echo $(grep -v '^#' $PROPERTIES | grep -e "HOST_DNS_NAME" | sed -e 's/.*=//'))
if [ -z "$HOST_DNS_NAME" ]; then
  HOST_DNS_NAME=`curl ifconfig.co 2>/dev/null`
fi

##########################################
# Clean up and prepare build directory
##########################################

[ -e $BUILD_DIR ] && rm -r $BUILD_DIR
mkdir -p $BUILD_DIR
mkdir -p $BUILD_DIR/container-data

##########################################
# create environment file
##########################################

DOTENV_FILE=$BUILD_DIR/environment
[ -e $DOTENV_FILE ] && rm $DOTENV_FILE
cat $PWD/src/environment >> $DOTENV_FILE
sed -i 's/__MONGO_PASSWORD__/'$MONGO_PASSWORD'/g' $DOTENV_FILE
sed -i 's#__BUILD_DIR__#'$BUILD_DIR'#g' $DOTENV_FILE

##########################################
# Build all URLs
##########################################

source $DOTENV_FILE
LEGEND_SDLC_PUBLIC_URL=http://$HOST_DNS_NAME:$LEGEND_SDLC_PORT
LEGEND_ENGINE_PUBLIC_URL=http://$HOST_DNS_NAME:$LEGEND_ENGINE_PORT
LEGEND_STUDIO_PUBLIC_URL=http://$HOST_DNS_NAME:$LEGEND_STUDIO_PORT
LEGEND_DEPOT_SERVER_URL=http://$HOST_DNS_NAME:$LEGEND_DEPOT_SERVER_PORT

##########################################
# Copy over configs and scripts
##########################################

cp -r $PWD/src/scripts $BUILD_DIR/scripts
cp -r $PWD/src/configs $BUILD_DIR/configs
cp -r $PWD/vault.properties $BUILD_DIR/configs/engine/vault.properties

##########################################
# Configure configs
##########################################

for f in $(find $BUILD_DIR/configs -type f); do

  sed -i 's/__GITLAB_OAUTH_CLIENT__/'$GITLAB_OAUTH_CLIENT'/g' $f
  sed -i 's/__GITLAB_OAUTH_SECRET__/'$GITLAB_OAUTH_SECRET'/g' $f

  sed -i 's/__HOST_DNS_NAME__/'$HOST_DNS_NAME'/g' $f

  sed -i 's/__LEGEND_SDLC_PORT__/'$LEGEND_SDLC_PORT'/g' $f
  sed -i 's#__LEGEND_SDLC_PUBLIC_URL__#'$LEGEND_SDLC_PUBLIC_URL'#g' $f
  sed -i 's/__LEGEND_SDLC_ADMIN_PORT__/'$LEGEND_SDLC_ADMIN_PORT'/g' $f

  sed -i 's#__LEGEND_DEPOT_SERVER_URL__#'$LEGEND_DEPOT_SERVER_URL'#g' $f
  sed -i 's/__LEGEND_DEPOT_SERVER_PORT__/'$LEGEND_DEPOT_SERVER_PORT'/g' $f

  sed -i 's/__LEGEND_ENGINE_PORT__/'$LEGEND_ENGINE_PORT'/g' $f
  sed -i 's#__LEGEND_ENGINE_URL__#'$LEGEND_ENGINE_PUBLIC_URL'#g' $f
  sed -i 's/__LEGEND_ENGINE_METADATA_PORT__/'$LEGEND_ENGINE_METADATA_PORT'/g' $f

  sed -i 's/__LEGEND_STUDIO_PORT__/'$LEGEND_STUDIO_PORT'/g' $f

  sed -i 's/__MONGO_HOST__/'$MONGO_SERVICE_NAME'/g' $f
  sed -i 's/__MONGO_PORT__/'$MONGO_PORT'/g' $f
  sed -i 's/__MONGO_USER__/'$MONGO_USER'/g' $f
  sed -i 's/__MONGO_PASSWORD__/'$MONGO_PASSWORD'/g' $f

  sed -i 's/__LEGEND_ENGINE_IMAGE_VERSION__/'$LEGEND_ENGINE_IMAGE_VERSION'/g' $f
  sed -i 's/__LEGEND_SDLC_IMAGE_VERSION__/'$LEGEND_SDLC_IMAGE_VERSION'/g' $f


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
