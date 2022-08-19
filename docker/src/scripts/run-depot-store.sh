#!/bin/bash

java \
  -XX:+ExitOnOutOfMemoryError \
  -Xss4M \
  -XX:MaxRAMPercentage=60 \
  -Dfile.encoding=UTF8 \
  -cp /app/bin/legend-depot-store-server-__LEGEND_DEPOT_STORE_IMAGE_VERSION__.jar \
  org.finos.legend.depot.store.server.LegendDepotStoreServer \
  server \
  /config/config.json
