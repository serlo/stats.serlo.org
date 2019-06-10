#!/bin/bash
for dashboard in "$@"
do
  curl -X POST -u ${grafana_user}:${grafana_password} -k -H "Content-Type: application/json" --data-binary @./dashboards/${dashboard}.json "${grafana_host}/api/dashboards/db"
done
