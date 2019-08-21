TERRAFORM_PATH := minikube

.PHONY: terraform_plan
# plan terraform
terraform_plan:
	cd $(TERRAFORM_PATH) && terraform plan

.PHONY: terraform_apply
# apply terraform with secrets
terraform_apply:
	cd $(TERRAFORM_PATH) && terraform apply -auto-approve

.PHONY: terraform_init
# init terraform environment
terraform_init: 
	cd $(TERRAFORM_PATH) && terraform get -update && terraform init

.PHONY: terraform_destroy
# destroy terraform environment
terraform_destroy:
	cd $(TERRAFORM_PATH) && terraform destroy
