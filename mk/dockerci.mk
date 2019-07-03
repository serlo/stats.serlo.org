#
# goals required for continous integration builds that push to gcr.io
#

ifeq ($(image_name),)
$(error image_name not defined)
endif

ifeq ($(local_image),)
$(error local_image not defined)
endif

ifeq ($(major_version),)
$(error major_version not defined)
endif

ifeq ($(minor_version),)
$(error minor_version not defined)
endif

gce_image := eu.gcr.io/serlo-shared/$(image_name)

.PHONY: docker_build_ci
# builds the docker image in the ci and pushes it to eu.gcr.io
docker_build_ci:
	 docker pull $(gce_image):$(version) 2>/dev/null >/dev/null || $(MAKE) docker_build docker_push

.PHONY: docker_build_minikube
# checks if the docker images is in the remote docker and builds it if not
docker_build_minikube:
	docker images | grep $(local_image) && echo "image $(local_image) already exists use docker_build" || $(MAKE) docker_build

.PHONY: docker_push
# push docker container to gcr.io registry
docker_push:
	docker tag $(local_image):latest $(gce_image):latest
	docker push $(gce_image):latest
	docker tag $(local_image):latest $(gce_image):$(major_version)
	docker push $(gce_image):$(major_version)
	docker tag $(local_image):latest $(gce_image):$(major_version).$(minor_version)
	docker push $(gce_image):$(major_version).$(minor_version)
	docker tag $(local_image):latest $(gce_image):$(major_version).$(minor_version).$(shell git log --pretty=format:'' | wc -l)
	docker push $(gce_image):$(major_version).$(minor_version).$(shell git log --pretty=format:'' | wc -l)
	docker tag $(local_image):latest $(gce_image):sha-$(shell git describe --dirty --always)
	docker push $(gce_image):sha-$(shell git describe --dirty --always)


