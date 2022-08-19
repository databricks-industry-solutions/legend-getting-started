#!/bin/bash

java \
  -XX:+ExitOnOutOfMemoryError \
  -Xss4M \
  -XX:MaxRAMPercentage=60 \
  -Dfile.encoding=UTF8 \
  -cp /app/bin/*.jar \
  org.finos.legend.sdlc.server.LegendSDLCServer \
  server \
  /config/config.yml
