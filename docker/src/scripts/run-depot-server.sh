#!/bin/bash

for FILE in `find /app/bin`; do
  echo $FILE
done

java \
  -cp /app/bin/legend-depot-server-__LEGEND_DEPOT_SERVER_IMAGE_VERSION__.jar \
  org.finos.legend.depot.server.LegendDepotServer \
  server \
  /config/config.json
