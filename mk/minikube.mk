.PHONY: project_create
# create a project minikube cluster and deploy the project resources,
# all in one target.
project_create: minikube_create project_deploy project_launch	

.PHONY: project_start
# initialize a minikube cluster and deploy this project,
# all in one target.
project_start: minikube_start project_launch

.PHONY: minikube_start
minikube_start:
	$(MAKE) -C $(infrastructure_repository)/minikube minikube_start

.PHONY:
minikube_create:
	$(MAKE) -C $(infrastructure_repository)/minikube minikube_create

.PHONY:
minikube_stop:
	$(MAKE) -C $(infrastructure_repository)/minikube minikube_stop

.PHONY:
minikube_delete:
	$(MAKE) -C $(infrastructure_repository)/minikube minikube_delete

.PHONY:
minikube_dashboard:
	$(MAKE) -C $(infrastructure_repository)/minikube minikube_dashboard

.PHONY:
kubectl_use_context:
	kubectl config use-context minikube

