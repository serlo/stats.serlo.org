#
# Describes deployment to the serlo cluster.
#


resource_importer = module.kpi.kubernetes_deployment.mysql-importer-cronjob
resource_aggregator = module.kpi.kubernetes_deployment.aggregator-cronjob
resource_grafana = module.kpi.kubernetes_deployment.grafana_deployment

.PHONY: deploy_aggregator
# force the deployment of the aggregator
deploy_aggregator:
	bash -c "cd $(env_folder) && terraform taint $(resource_aggregator)"
	$(MAKE) terraform_apply

.PONY: deploy_importer
# force the deployment of the mysql importer
deploy_importer:
	bash -c "cd $(env_folder) && terraform taint $(resource_importer)"
	$(MAKE) terraform_apply

.PONY: deploy_grafana
# force the deployment of grafana
deploy_grafana:
	bash -c "cd $(env_folder) && terraform taint $(resource_grafana)"
	$(MAKE) terraform_apply

.NOTPARALLEL:
