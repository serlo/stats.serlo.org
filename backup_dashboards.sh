HOST=https://stats.dev.serlo.local

mkdir -p dashboards

export USER_PASSWORD=admin:admin

for dash in $(curl -u $USER_PASSWORD --insecure -sSL -k ${HOST}/api/search\?query\=\& | jq '.' | grep -i uri|awk -F '"uri": "' '{ print $2 }'|awk -F '"' '{print $1 }'); do
  echo $dash
  curl -u $USER_PASSWORD --insecure -sSL -k "${HOST}/api/dashboards/${dash}" > dashboards/$(echo ${dash}|sed 's,db/,,g').json
done
