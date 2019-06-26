#
# goals required for continous integration builds that push to gcr.io
#

ifeq ($(image_name),)
$(error image_name not defined)
endif

ifeq ($(minor_version),)
$(error minor_version not defined)
endif

.PHONY: docker_push
# push docker container to gcr.io registry
docker_push:
	gce_image := eu.gcr.io/serlo-containers/$(image_name)
	local_image := serlo/$(image_name)
	patch_version := $(minor_version).$(shell git log --pretty=format:'' | wc -l)
	revision := "$(shell git describe --dirty --always)"
	docker tag $(local_image):latest $(gce_image):latest
	docker push $(gce_image):latest
	docker tag $(local_image):latest $(gce_image):$(minor_version)
	docker push $(gce_image):$(minor_version)
	docker tag $(local_image):latest $(gce_image):$(patch_version)
	docker push $(gce_image):$(patch_version)
	docker tag $(local_image):latest $(gce_image):sha-$(revision)
	docker push $(gce_image):sha-$(revision)


