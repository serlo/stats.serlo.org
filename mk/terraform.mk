.PHONY: terraform_init
ifeq ($(env_name),minikube)
terraform_auto_approve=-auto-approve

.PHONY: terraform_plan
# plan terraform
terraform_plan:
	# just make sure we know what we are doing
	ln -s $(infrastructure_repository)/modules modules
	terraform fmt -recursive minikube 
	cd minikube && terraform plan

.PHONY: terraform_apply
# apply terraform with secrets
terraform_apply:
	# just make sure we know what we are doing
	ln -s $(infrastructure_repository)/modules modules
	terraform fmt -recursive minikube 
	cd minikube && terraform apply $(terraform_auto_approve)

.PHONY: terraform_init
# init terraform environment
terraform_init: 
	ln -s $(infrastructure_repository)/modules modules
	cd minikube && terraform init

else
ifndef cloudsql_credential_filename
$(error variable cloudsql_credential_filename not set)
endif

ifndef gcloud_env_name
$(error variable env_name not set)
endif

endif

