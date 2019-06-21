#!/bin/bash
set -e
echo "wait for grafana to be ready"
until curl --fail -k "${grafana_host}/login" > /dev/null -s
do
  sleep 5
done

for dashboard in ./dashboards/*.json;
do
  echo -n "restoring ${dashboard}... " 
  jq ".overwrite=true" ${dashboard} | curl -X POST -u ${grafana_user}:${grafana_password} -k -H "Content-Type: application/json" --data-binary @- "${grafana_host}/api/dashboards/db" --silent | jq ".status" -r
done
