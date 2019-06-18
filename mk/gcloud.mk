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