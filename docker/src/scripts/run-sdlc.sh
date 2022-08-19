#!/bin/bash

for FILE in `find /app/bin`; do
  echo $FILE
done

java \
  -XX:+ExitOnOutOfMemoryError \
  -Xss4M \
  -XX:MaxRAMPercentage=60 \
  -Dfile.encoding=UTF8 \
  -cp /app/bin/legend-sdlc-server-__LEGEND_SDLC_IMAGE_VERSION-shaded.jar \
  org.finos.legend.sdlc.server.LegendSDLCServer \
  server \
  /config/config.yml
