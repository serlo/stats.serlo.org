#
# Describes deployment to the serlo cluster.
#

# location of the current serlo database dump
export dump_location ?= gs://serlo_dev_terraform/sql-dumps/dump-2019-05-13.zip

resource_importer = module.kpi.kubernetes_deployment.mysql-importer-cronjob
resource_aggregator = module.kpi.kubernetes_deployment.aggregator-cronjob
resource_grafana = module.kpi.kubernetes_deployment.grafana_deployment

.PHONY: provide_athene2_content
# upload the current database dump to the content provider container
provide_athene2_content:
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

.PONY: deploy_grafana
# force the deployment of grafana
deploy_grafana:
	cd $(infrastructure_repository)/$(env_folder) && terraform taint $(resource_grafana) && $(MAKE) terraform_apply

.NOTPARALLEL:
