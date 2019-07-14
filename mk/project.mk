.PHONY: project_create
# create a project minikube cluster and deploy the project resources,
# all in one target.
ifeq ($(env_name),minikube)
project_create: minikube_create project_deploy project_launch
else
project_create: project_deploy project_launch
endif

.PHONY: project_deploy
# deploy the project to an already running cluster
ifeq ($(env_name),minikube)
project_deploy: docker_minikube_setup terraform_apply grafana_restore_dashboards grafana_add_default_users grafana_set_preferences
else
project_deploy: terraform_apply provide_athene2_content grafana_restore_dashboards grafana_add_default_users grafana_set_preferences
endif

.PHONY: project_launch
# launch the grafana dashboard
project_launch:
	xdg-open $(grafana_host)/login 2>/dev/null >/dev/null &

.PHONY: project_smoketest
# run smoketest for kpi project
project_smoketest: kubectl_use_context
	$(MAKE) -C smoketest

