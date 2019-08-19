#!/bin/sh
set -e
SERLO_PASSWORD=$GF_SECURITY_SERLO_PASSWORD
URL="localhost:3000"
GRAFANA_CURL_AUTH="-k -u admin:$GF_SECURITY_ADMIN_PASSWORD -s -S"

echo "wait for grafana to be ready"
until curl --fail -k "$URL/login" > /dev/null -s
do
  sleep 5
done

curl $GRAFANA_CURL_AUTH -XGET $URL/api/users \
    | grep serlo >/dev/null && echo "user serlo already created"  \
    || \
	curl $GRAFANA_CURL_AUTH -XPOST \
		-H 'Content-Type: application/json' \
		-d "{\"name\":\"serlo\",\"email\":\"kpi-user@serlo.org\",\"login\":\"serlo\",\"password\":\"$SERLO_PASSWORD\"}" \
	$URL/api/admin/users >/dev/null && echo "user serlo created"

#get dashboard by uid of author activity
curl $GRAFANA_CURL_AUTH \
    -XPUT  \
    -H 'Accept: application/json' \
    -H 'Content-Type: application/json' \
    -d "{\"theme\":\"\", \
        \"homeDashboardId\":$(curl $GRAFANA_CURL_AUTH \
                -XGET \
                -H 'Accept: application/json' \
                -H 'Content-Type: application/json' \
                $URL/api/dashboards/uid/yS5BVkWZk \
            | jq '.dashboard.id'),\
        \"timezone\":\"browser\" \
    }" \
    $URL/api/org/preferences && echo "successfully set home screen!"


