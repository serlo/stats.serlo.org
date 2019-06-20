#
# Describes deployment to the serlo cluster.
#

# location of the current serlo database dump
export dump_location ?= gs://serlo_dev_terraform/sql-dumps/dump-2019-05-13.zip

# set the appropriate docker environment
ifeq ($(env_name),minikube)
	DOCKER_ENV ?= $(shell minikube docker-env)
	env_folder = minikube/kpi
else
    ifeq ($(env_name),dev)
    	DOCKER_ENV ?= ""
    	env_folder = live/dev
    else
        ifneq ($(subst help,,$(MAKECMDGOALS)),)
    		$(error only env_name [minikube,dev] are supported)
        endif
    endif
endif


.PHONY: terraform_init
# initialize terraform in the infrastructure repository
terraform_init:
	$(MAKE) -C $(infrastructure_repository)/$(env_folder) terraform_init

.PHONY: terraform_plan
# plan the terraform provisioning in the cluster
terraform_plan: build_images terraform_init
	$(MAKE) -C $(infrastructure_repository)/$(env_folder) terraform_plan

.PHONY: terraform_apply
# apply the terraform provisoining in the cluster
terraform_apply: build_images terraform_init
	$(MAKE) -C $(infrastructure_repository)/$(env_folder) terraform_apply

.PHONY: build_images
.ONESHELL:
# build docker images for local dependencies in the cluster
build_images:
	@eval "$(DOCKER_ENV)"
	if (docker images | grep kpi-$* -q) ; then
		echo "image for $* already exists! (use make build_images_forced for a new build)"
	else
		$(MAKE) build_images_forced
	fi

.PHONY: build_images_forced
.ONESHELL:
# build docker images for local dependencies in the cluster
build_images_forced:
	@eval "$(DOCKER_ENV)"
	$(MAKE) -C mysql-importer docker-build
	$(MAKE) -C aggregator docker-build
	$(MAKE) -C dbsetup docker-build
	$(MAKE) -C dbdump docker-build

# download the database dump
tmp/dump.zip:
	mkdir -p tmp
	echo "downloading latest mysql dump from gcloud"
	gsutil cp $(dump_location) $@

# unzip database dump
tmp/dump.sql: tmp/dump.zip
	unzip $< -d tmp
	touch $@

.PHONY: provide_athene2_content
# upload the current database dump to the content provider container
provide_athene2_content: tmp/dump.sql
	bash scripts/provide-athene2-content.sh

.NOTPARALLEL:
