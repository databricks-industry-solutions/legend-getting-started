#!/usr/bin/env sh

LEGEND_HOME="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

case "$1" in
configure)
  ${LEGEND_HOME}/setup.sh
  ;;
start)
  $0 configure
  sudo docker-compose --env-file ${LEGEND_HOME}/dist/environment up --detach
  ;;
stop)
  sudo docker-compose --env-file ${LEGEND_HOME}/dist/environment down
  ;;
restart)
  $0 stop
  $0 start
  ;;
clean)
  $0 stop
  rm -rf ${LEGEND_HOME}/dist
  IMAGES=`sudo docker images | awk '{print $3}' | grep -v IMAGE`
  for IMAGE in $IMAGES:
  do
    sudo docker rmi $IMAGE
  done
  sudo docker volume prune
  ;;
*)
   echo "Usage: $0 {start|stop|restart|configure|clean}"
esac

exit 0