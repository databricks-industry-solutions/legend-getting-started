#!/bin/bash

java \
  -XX:+ExitOnOutOfMemoryError \
  -Xss4M \
  -XX:MaxRAMPercentage=60 \
  -Dfile.encoding=UTF8 \
  -cp /app/bin/legend-depot-server-__LEGEND_DEPOT_SERVER_IMAGE_VERSION__.jar \
  org.finos.legend.depot.server.LegendDepotServer \
  server \
  /config/config.json
