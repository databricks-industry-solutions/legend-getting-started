#!/usr/bin/env sh

LEGEND_HOME="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

case "$1" in
configure)
  ${LEGEND_HOME}/setup.sh
  ;;
start)
  sudo docker-compose --env-file ${LEGEND_HOME}/dist/environment up --detach
  ;;
stop)
  sudo docker-compose --env-file ${LEGEND_HOME}/dist/environment down
  ;;
restart)
  $0 stop
  $0 start
  ;;
*)
   echo "Usage: $0 {start|stop|restart|configure}"
esac

exit 0