#!/bin/bash

for FILE in `find /app/bin`; do
  echo $FILE
done

java \
  -XX:+ExitOnOutOfMemoryError \
  -Xss4M \
  -XX:MaxRAMPercentage=60 \
  -Dfile.encoding=UTF8 \
  -cp /app/bin/webapp-content:/app/bin/* \
  org.finos.legend.server.shared.staticserver.Server \
  server \
  /config/httpConfig.json
