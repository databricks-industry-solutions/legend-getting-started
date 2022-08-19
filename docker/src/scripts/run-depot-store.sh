#!/bin/bash

for FILE in `find /app/bin`; do
  echo $FILE
done

java \
  -cp /app/bin/legend-depot-store-server-__LEGEND_DEPOT_STORE_IMAGE_VERSION__.jar \
  org.finos.legend.depot.store.server.LegendDepotStoreServer \
  server \
  /config/config.json
