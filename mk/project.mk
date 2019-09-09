#
# Targets for the KPI project
#

.PHONY: project_start
# create a project minikube cluster and deploy the project resources, all in
# one target.
project_start: minikube_start build_local docker_minikube_setup project_deploy \
	minikube_launch

.PHONY: project_deploy
# deploy the project to an already running cluster
project_deploy: terraform_init terraform_apply

.PHONY: project_smoketest
# run smoketest for kpi project
project_smoketest: kubectl_use_context
	$(MAKE) -C smoketest
