#!/bin/bash
for dashboard in ./dashboards/*.json;
do
  jq ".overwrite=true" ${dashboard} | curl -X POST -u ${grafana_user}:${grafana_password} -k -H "Content-Type: application/json" --data-binary @- "${grafana_host}/api/dashboards/db"
done
