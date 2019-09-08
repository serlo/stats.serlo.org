.PHONY: project_start
# create a project minikube cluster and deploy the project resources, all in one target.
project_start: minikube_start docker_minikube_setup build_local project_deploy minikube_launch

.PHONY: project_deploy
# deploy the project to an already running cluster
project_deploy: docker_minikube_setup terraform_init terraform_apply 

.PHONY: project_smoketest
# run smoketest for kpi project
project_smoketest: kubectl_use_context
	$(MAKE) -C smoketest
