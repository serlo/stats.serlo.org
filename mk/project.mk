
.PHONY: project_start
# create a project minikube cluster and deploy the project resources,
# all in one target.
project_start: project_deploy project_launch

ADDITIONAL_STEPS  := 
ifeq ($(env_name),minikube)
	ADDITIONAL_STEPS := minikube_start docker_minikube_setup build_local
endif

.PHONY: project_deploy
# deploy the project to an already running cluster
project_deploy: $(ADDITIONAL_STEPS) terraform_init terraform_apply grafana_restore_dashboards grafana_add_default_users grafana_set_preferences

.PHONY: project_launch
# launch the grafana dashboard
project_launch:
	xdg-open $(grafana_host)/login 2>/dev/null >/dev/null &

.PHONY: project_smoketest
# run smoketest for kpi project
project_smoketest: kubectl_use_context
	$(MAKE) -C smoketest

