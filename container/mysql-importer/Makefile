image_name="kpi-mysql-importer"
local_image=serlo/$(image_name)

major_version=1
minor_version=0
#patch version is automatically generated from minor_version + number of commits so we do not need to maintain it

include ../../mk/dockerci.mk

cron_pattern=*/15 * * * *

.PHONY: docker_build_ci
# builds the docker image in the ci and pushes it to eu.gcr.io
docker_build_ci:
	@../../scripts/check_changes.sh . ; if [ $$? != 0 ] ; then $(MAKE) docker_build && $(MAKE) docker_push; fi

.PHONY: docker_build_minikube
docker_build_minikube:
	docker images | grep $(image_name) && echo "image $(image_name) already exists use build_image_forced" || $(MAKE) docker_build

#
.PHONY: docker_build
.ONE_SHELL:
# build the docker container
docker_build:
	docker build --build-arg git_revision=$(shell git log | head -n 1 | cut  -f 2 -d ' ') --build-arg cron_pattern="$(cron_pattern)" -t $(local_image) .

.PHONY: docker_run
# run the docker container agains databases in minikube
docker_run:
	sed "s/MINIKUBE_IP/$(shell minikube ip)/" config.yaml >config-minikube.yaml
	docker run --network=host -v $(CURDIR)/config-minikube.yaml:/tmp/config.yaml --rm $(local_image)
