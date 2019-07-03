#
# Describes deployment to the serlo cluster.
#

# location of the current serlo database dump
export dump_location ?= gs://serlo_dev_terraform/sql-dumps/dump-2019-05-13.zip

resource_importer = module.kpi.kubernetes_deployment.mysql-importer-cronjob
resource_aggregator = module.kpi.kubernetes_deployment.aggregator-cronjob

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
deploy_aggregator:
	cd $(infrastructure_repository)/$(env_folder) && terraform taint $(resource_aggregator) && $(MAKE) terraform_apply

.PONY: deploy_importer
# force the deployment of the mysql importer
deploy_importer:
	cd $(infrastructure_repository)/$(env_folder) && terraform taint $(resource_importer) && $(MAKE) terraform_apply

.NOTPARALLEL:
