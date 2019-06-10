#
# Makefile
# 
# Purpose:
# - automate the upload and backup of current grafana dashboards
# - run smoke tests agains local minikube cluster or gcloud dev/staging/production
# 

grafana_host ?= https://stats.dev.serlo.local
grafana_user ?= admin
grafana_password ?= admin

.PHONY: dashb-backup
dashb-backup:
	curl -X GET -u $(grafana_user):$(grafana_password) -k "${grafana_host}/api/dashboards/db/author-activity" | python -m json.tool > dashboards/author-activity.json
	curl -X GET -u $(grafana_user):$(grafana_password) -k "${grafana_host}/api/dashboards/db/registrations" | python -m json.tool > dashboards/registrations.json


.PHONY: dashb-upload
dashb-upload:
	curl -X POST -u $(grafana_user):$(grafana_password) -k -H "Content-Type: application/json" --data-binary @./dashboards/author-activity.json "${grafana_host}/api/dashboards/db"
	curl -X POST -u $(grafana_user):$(grafana_password) -k -H "Content-Type: application/json" --data-binary @./dashboards/registrations.json "${grafana_host}/api/dashboards/db"

.PHONY: smoketest
smoketest:
	cd test && go run main.go
