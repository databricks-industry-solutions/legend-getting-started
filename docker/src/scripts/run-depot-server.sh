#!/bin/bash

java \
  -cp /app/bin/*.jar \
  org.finos.legend.depot.server.LegendDepotServer \
  server \
  /config/config.json
