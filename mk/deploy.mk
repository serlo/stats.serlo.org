#
# Describes deployment to the serlo cluster.
#

export dump_location ?= gs://serlo_dev_terraform/sql-dumps/dump-2019-05-13.zip

# set the appropriate docker environment
ifeq ($(env_name),minikube)
	DOCKER_ENV ?= $(shell minikube docker-env)
else
    DOCKER_ENV ?= $(error non-minikube environment is not implemented, yet!)
endif

# initialize terraform in the infrastructure repository
.PHONY: terraform_init
terraform_init:
	(cd $(infrastructure_repository)/minikube/kpi && terraform init)

# deploy the KPI infrastructure to the minikube cluster
.PHONY: terraform_apply
terraform_apply: build_image_mysql-importer build_image_athene2-content-provider terraform_init
	(cd $(infrastructure_repository)/minikube/kpi && terraform apply $(terraform_auto_approve))

# build docker images for local dependencies in the cluster
.PHONY: build_image_%
.ONESHELL:
build_image_%:
	@eval "$(DOCKER_ENV)"
	if (docker images | grep kpi-$* -q) ; then
		echo "image for $* already exists! (use docker rmi serlo/kpi-$* to force a new build)"
	else
		$(MAKE) -C $* docker-build
	fi

# download the database dump
tmp/dump.zip:
	mkdir -p tmp
	echo "downloading latest mysql dump from gcloud"
	gsutil cp $(dump_location) $@

# unzip database dump
tmp/dump.sql: tmp/dump.zip
	unzip $< -d tmp
	touch $@

# upload the current database dump to the content provider container
.PHONY: provide_athene2_content
provide_athene2_content: tmp/dump.sql
	bash scripts/provide-athene2-content.sh

.NOTPARALLEL:
