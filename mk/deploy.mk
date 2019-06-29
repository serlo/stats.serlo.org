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

.PHONY: build_images
.ONESHELL:
# build docker images for local dependencies in the cluster
build_images:
	@eval "$(DOCKER_ENV)"
	for build in container/*/; do \
		$(MAKE) -C $$build build_image || exit 1; \
	done
	for build in $(infrastructure_repository)/container/*/; do \
		$(MAKE) -C $$build build_image || exit 1;
	done

.PHONY: push_grafana_image
push_grafana_image:
	docker pull eu.gcr.io/serlo-containers/grafana:6.2.5 || docker pull grafana/grafana:6.2.5 ; \
		docker tag grafana/grafana:6.2.5 eu.gcr.io/serlo-containers/grafana:6.2.5; \
		docker push eu.gcr.io/serlo-containers/grafana:6.2.5


.PHONY: build_images_forced
.ONESHELL:
# build docker images for local dependencies in the cluster
build_images_forced:
	@eval "$(DOCKER_ENV)"
	for build in container/*/; do \
		$(MAKE) -C $$build docker_build || exit 1;
	done
	for build in $(infrastructure_repository)/container/*/; do \
		$(MAKE) -C $$build docker_build || exit 1;
	done
# download the database dump
tmp/dump.zip:
	mkdir -p tmp
	echo "downloading latest mysql dump from gcloud"
	gsutil cp $(dump_location) $@

# unzip database dump
tmp/dump.sql: tmp/dump.zip
	unzip $< -o -d tmp
	touch $@

.PHONY: provide_athene2_content
# upload the current database dump to the content provider container
provide_athene2_content: tmp/dump.sql
	bash scripts/setup-athene2-db.sh


.NOTPARALLEL:
