#
# Describes deployment to the serlo cluster.
#

# location of the current serlo database dump
export dump_location ?= gs://serlo_dev_terraform/sql-dumps/dump-2019-05-13.zip
IMAGES := aggregator mysql-importer dbdump dbsetup varnish
$(info container images: $(IMAGES))

# set the appropriate docker environment
ifeq ($(env_name),minikube)
	DOCKER_ENV ?= $(shell minikube docker-env)
	env_folder = minikube/kpi
else
    	DOCKER_ENV ?= ""
    	env_folder = "live/$(env_name)"
endif

.PHONY: terraform_init
# initialize terraform in the infrastructure repository
terraform_init:
	$(MAKE) -C $(infrastructure_repository)/$(env_folder) terraform_init

.PHONY: terraform_plan
# plan the terraform provisioning in the cluster
terraform_plan: terraform_init
	$(MAKE) -C $(infrastructure_repository)/$(env_folder) terraform_plan

.PHONY: terraform_apply
# apply the terraform provisioning in the cluster
terraform_apply: terraform_init
	#if [ "$(env_name)" = "minikube" ] ; then $(MAKE) build_images; fi
	$(MAKE) -C $(infrastructure_repository)/$(env_folder) terraform_apply

.PHONY: build_image_%
.ONESHELL:
# build a specific docker image
build_image_%:
	@set -e
	eval "$(DOCKER_ENV)"
	if test -d container/$* ; then \
		$(MAKE) -C container/$* build_image; \
	else \
		$(MAKE) -C $(infrastructure_repository)/container/$* build_image; \
	fi

.PHONY: build_image_forced_%
.ONESHELL:
# force rebuild of a specific docker image
build_image_forced_%:
	@set -e
	eval "$(DOCKER_ENV)"
	if test -d container/$* ; then \
		$(MAKE) -C container/$* docker_build; \
	else \
		$(MAKE) -C $(infrastructure_repository)/container/$* docker_build; \
	fi

.PHONY: build_images
# build docker images for local dependencies in the cluster
build_images: $(foreach CONTAINER,$(IMAGES),build_image_$(CONTAINER))

.PHONY: build_images_forced
# build docker images for local dependencies in the cluster (forced rebuild)
build_images_forced: $(foreach CONTAINER,$(IMAGES),build_image_forced_$(CONTAINER))

.PHONY: push_grafana_image
push_grafana_image:
	docker pull eu.gcr.io/serlo-containers/grafana:6.2.2 || docker pull grafana/grafana:6.2.2 ; \
		docker tag grafana/grafana:6.2.2 eu.gcr.io/serlo-containers/grafana:6.2.2; \
		docker push eu.gcr.io/serlo-containers/grafana:6.2.2

# download the database dump
tmp/dump.zip:
	mkdir -p tmp
	echo "downloading latest mysql dump from gcloud"
	gsutil cp $(dump_location) $@

.PHONY: provide_athene2_content
# upload the current database dump to the content provider container
provide_athene2_content: tmp/dump.sql
	$(MAKE) kubectl_use_context
	bash scripts/setup-athene2-db.sh


.NOTPARALLEL:
