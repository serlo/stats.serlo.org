#
# Describes deployment to the serlo cluster.
#

# location of the current serlo database dump
export dump_location ?= gs://serlo_dev_terraform/sql-dumps/dump-2019-05-13.zip

# download the database dump
tmp/dump.zip:
	mkdir -p tmp
	echo "downloading latest mysql dump from gcloud"
	gsutil cp $(dump_location) $@

.PHONY: provide_athene2_content
# upload the current database dump to the content provider container
provide_athene2_content: tmp/dump.sql
	$(MAKE) kubectl_use_context
	bash scripts/setup-athene2-db.sh

.PHONY: deploy_aggregator
# force the deployment of the aggregator
deploy_aggregator: kubectl_use_context
	kubectl patch deployment aggregator-cronjob --namespace kpi  -p "{\"spec\": {\"template\": {\"metadata\": { \"labels\": {  \"redeploy\": \"$$(date +%s)\"}}}}}"

.PONY: deploy_importer
# force the deployment of the mysql importer
deploy_importer: kubectl_use_context
	kubectl patch deployment mysql-importer-cronjob --namespace kpi  -p "{\"spec\": {\"template\": {\"metadata\": { \"labels\": {  \"redeploy\": \"$$(date +%s)\"}}}}}"


.NOTPARALLEL:
