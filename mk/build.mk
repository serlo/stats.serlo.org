# set the appropriate docker environment
ifeq ($(env_name),minikube)
	DOCKER_ENV ?= $(shell minikube docker-env)
else
    	DOCKER_ENV ?= ""
    	env_folder = "live/$(env_name)"
endif

script = scripts/docker-setup-minikube.sh
image_path = eu.gcr.io/serlo-shared

.PHONY: build_ci
# build docker images for ci
build_ci:
	@set -e ; $(MAKE) -C container/aggregatgor docker_build_ci
	@set -e ; $(MAKE) -C container/mysql-importer docker_build_ci

.PHONY: docker_minikube_setup
# setup minikube docker with eu.gcr.io docker
docker_minikube_setup:
	$(script) $(image_path)/kpi-aggregator latest
	$(script) $(image_path)/kpi-mysql-importer latest
	$(script) $(image_path)/athene2-dbsetup-cronjob latest
	$(script) $(image_path)/grafana 6.2.5

.PHONY: build_local
# build docker images locally and copy them to minikube
build_local:
	@set -e ; eval "$(DOCKER_ENV)" ; $(MAKE) -C container/aggregator docker_build
	@set -e ; eval "$(DOCKER_ENV)" ; $(MAKE) -C container/mysql-importer docker_build

