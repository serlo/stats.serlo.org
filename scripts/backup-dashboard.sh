#!/bin/bash
for dashboard in "author-activity registrations"
do
	curl -s -X GET -u ${grafana_user}:${grafana_password} -k "${grafana_host}/api/dashboards/db/${dashboard}" | python -m json.tool > dashboards/tmp.json
	line=$(cat dashboards/tmp.json | grep -n '[[:space:]]\{8\}\"id\"\:' | grep -v '[[:space:]]\{9\}' | awk '{ print $1 }' | sed 's/://')
	if [ "${line}" != "" ] ; then 
		sed "${line}d" dashboards/tmp.json >"dashboards/${dashboard}.json"
	fi
	rm dashboards/tmp.json
done
