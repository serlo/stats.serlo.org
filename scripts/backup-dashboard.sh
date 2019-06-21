#!/bin/bash
set -e

dashboards=$(curl -s -X GET -u ${grafana_user}:${grafana_password} -k "${grafana_host}/api/search?type=dash-db" | jq ".[] | .uri" -r | cut -d "/" -f 2)

for dashboard in ${dashboards}
do
    echo "backing up ${dashboard}..."
    curl -s -X GET -u ${grafana_user}:${grafana_password} -k "${grafana_host}/api/dashboards/db/${dashboard}" | jq "del(.dashboard.id)" > dashboards/${dashboard}.json 
done
