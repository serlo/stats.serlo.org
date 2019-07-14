export env_name = minikube
export secret_var_file_param = -var-file  secret.tfvars
infrastructure_repository ?= ../infrastructure

.PHONY: project_create
# create a project minikube cluster and deploy the project resources,
# all in one target.
project_create: minikube_create project_deploy project_launch	

.PHONY: project_start
# initialize a minikube cluster and deploy this project,
# all in one target.
project_start: minikube_start project_launch

.PHONY:
kubectl_use_context:
	kubectl config use-context minikube

