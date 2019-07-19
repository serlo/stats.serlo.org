image_name="kpi-mysql-importer"
local_image=eu.gcr.io/serlo-shared/$(image_name)

major_version=1
minor_version=2
patch_version=1
version=$(major_version).$(minor_version).$(patch_version) 

include ../../mk/dockerci.mk

cron_pattern=*/15 * * * *

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
