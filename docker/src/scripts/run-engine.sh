#!/bin/bash

java \
  -XX:+ExitOnOutOfMemoryError \
  -Xss4M \
  -XX:MaxRAMPercentage=60 \
  -Dfile.encoding=UTF8 \
  -cp /app/bin/legend-engine-server-__LEGEND_ENGINE_IMAGE_VERSION__-shaded.jar \
  org.finos.legend.engine.server.Server \
  server \
  /config/config.json
