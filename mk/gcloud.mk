.PHONY: project_create
# create a project minikube cluster and deploy the project resources,
# all in one target.
project_create: project_deploy project_launch	

.PHONY: project_start
# initialize a minikube cluster and deploy this project,
# all in one target.
project_start: 
	$(MAKE) -C $(infrastructure_repository)/live/dev kubectl-use-context
	$(MAKE) project_launch

gcloud_dashboard:
	xdg-open https://console.cloud.google.com/kubernetes/workload?project=serlo-dev&workload_list_tablesize=50 2>/dev/null >/dev/null &

kubectl_use_context:
	kubectl config use-context gke_serlo-$(env_name)_europe-west3-a_serlo-$(env_name)-cluster


tools_run_postgres_cloud_sql_proxy:
	$(MAKE) -C $(infrastructure_repository)/live/dev run-postgres-cloud-sql-proxy
