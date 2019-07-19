.PHONY: terraform_init
ifeq ($(env_name),minikube)
terraform_auto_approve=-auto-approve

ifeq ($(infrastructure_repository),)
$(error infrastructure_repository not defined)
endif

.PHONY: terraform_plan
# plan terraform
terraform_plan:
	# just make sure we know what we are doing
	test -d modules || ln -s $(infrastructure_repository)/modules modules
	terraform fmt -recursive $(env_folder) 
	cd $(env_folder) && terraform plan

.PHONY: terraform_apply
# apply terraform with secrets
terraform_apply:
	# just make sure we know what we are doing
	test -d modules || ln -s $(infrastructure_repository)/modules modules
	terraform fmt -recursive $(env_folder) 
	cd $(env_name) && terraform apply $(terraform_auto_approve)

.PHONY: terraform_init
# init terraform environment
terraform_init: 
	test -d modules || ln -s $(infrastructure_repository)/modules modules
	cd $(env_name) && terraform init

.PHONY: terraform_destroy
# destroy terraform environment
terraform_destroy:
	cd $(env_name) && terraform destroy -var-file secrets/terraform-$(env_name).tfvars

else
.PHONY: terraform_init
# init terraform environment
.ONESHELL:
terraform_init: 
	#remove secrets and load latest secret from gcloud
	cd $(env_folder)
	rm -rf secrets
	gsutil -m cp -R gs://serlo_$(env_name)_terraform/secrets/ .
	terraform init

.PHONY: terraform_plan
# plan terrform with secrets
.ONESHELL:
terraform_plan:
	cd $(env_folder)
	terraform fmt -recursive ../../
	terraform plan -var-file secrets/terraform-$(env_name).tfvars

.PHONY: terraform_apply
# apply terraform with secrets
.ONESHELL:
terraform_apply:
	# just make sure we know what we are doing
	cd $(env_folder)
	terraform fmt -recursive ../../
	terraform apply -var-file secrets/terraform-$(env_name).tfvars

.PHONY: terraform_destroy
# destroy terraform with secrets
.ONESHELL:
terraform_destroy:
	# just make sure we know what we are doing
	cd $(env_folder)
	terraform fmt -recursive ../../
	terraform destroy -var-file secrets/terraform-$(env_name).tfvars
endif

