# set the appropriate docker environment
DOCKER_ENV ?= $(shell minikube docker-env)

PULL_SCRIPT = scripts/docker-setup-minikube.sh
IMAGE_PATH = eu.gcr.io/serlo-shared

.PHONY: build_ci
# build docker images for ci
build_ci:
	$(MAKE) -C container/aggregator docker_build_ci
	$(MAKE) -C container/mysql-importer docker_build_ci
	$(MAKE) -C container/grafana docker_build_ci

.PHONY: docker_minikube_setup
# pull images from eu.gcr.io to minikube docker
docker_minikube_setup:
	$(PULL_SCRIPT) $(IMAGE_PATH)/kpi-aggregator latest
	$(PULL_SCRIPT) $(IMAGE_PATH)/kpi-mysql-importer latest
	$(PULL_SCRIPT) $(IMAGE_PATH)/athene2-dbsetup-cronjob latest
	$(PULL_SCRIPT) $(IMAGE_PATH)/grafana 6.2.5

.PHONY: build_local
# build docker images locally and copy them to minikube
build_local: build_grafana build_aggregator build_mysql-importer

.PHONY: build_%
# build {grafana|aggregator|mysql-importer} image inside the minikube docker
build_%:
	@set -e ; eval "$(DOCKER_ENV)" ; $(MAKE) -C container/$* docker_build

