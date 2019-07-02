IMAGES := aggregator mysql-importer
SHARED_IMAGES := dbsetup grafana

$(info container images: $(IMAGES) $(SHARED_IMAGES))

# set the appropriate docker environment
ifeq ($(env_name),minikube)
	DOCKER_ENV ?= $(shell minikube docker-env)
	env_folder = minikube/kpi
else
    	DOCKER_ENV ?= ""
    	env_folder = "live/$(env_name)"
endif

.PHONY: build_image_minikube_%
# build a specific docker image
build_image_minikube_%:
	@set -e ; eval "$(DOCKER_ENV)" ; $(MAKE) -C container/$* docker_build_minikube

.PHONY: build_image_minikube_shared_%
# build a specific docker image
build_image_minikube_shared_%:
	@set -e ; eval "$(DOCKER_ENV)" ; $(MAKE) -C $(sharedimage_repository)/container/$* docker_build_minikube

.PHONY: build_image_minikube_forced_%
# force rebuild of a specific docker image
build_image_minikube_forced_%:
	@set -e ; eval "$(DOCKER_ENV)" ; $(MAKE) -C container/$* docker_build


.PHONY: build_image_minikube_shared_forced_%
# force rebuild of a specific docker image
build_image_minikube_shared_forced_%:
	 @set -e ; eval "$(DOCKER_ENV)" ; $(MAKE) -C $(sharedimage_repository)/container/$* docker_build

.PHONY: build_images_ci
# build docker images for ci
build_images_ci: $(foreach CONTAINER,$(IMAGES),build_image_ci_$(CONTAINER))

.PHONY: build_images_minikube
# build docker images for local dependencies in the cluster
build_images_minikube: $(foreach CONTAINER,$(IMAGES),build_image_minikube_$(CONTAINER)) $(foreach CONTAINER,$(SHARED_IMAGES),build_image_minikube_shared_$(CONTAINER))

.PHONY: build_images_minikube_forced
# build docker images for local dependencies in the cluster (forced rebuild)
build_images_minikube_forced: $(foreach CONTAINER,$(IMAGES),build_image_minikube_forced_$(CONTAINER)) $(foreach CONTAINER,$(SHARED_IMAGES),build_image_minikube_shared_forced_$(CONTAINER))

