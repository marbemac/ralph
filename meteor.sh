#!/bin/bash

APP_NAME=ralph

case "$1" in
run )
meteor --settings config/settings.json
;;
deploy )

echo Deploying...
modulus deploy -p ralph-production -n 0.10.29 -t meteor -D false

;;
* )
cat <<'ENDCAT'
./meteor.sh [action]

Available actions:

  run     - Run locally
  deploy  - Deploy the app to the server
ENDCAT
;;
esac
