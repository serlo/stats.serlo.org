image_name=kpi-aggregator
minor_version=1.0
#patch version is automatically generated from minor_version + number of commits so we do not need to maintain it

include ../../mk/dockerci.mk

cron_pattern=*/60 * * * *

.PHONY: build_image
build_image:
	docker images | grep $(image) && echo "image $(image) already exists use build_image_forced" || $(MAKE) docker_build

.PHONY: docker_build
# build docker container
docker_build:
	docker build --build-arg git_revision=$(shell git log | head -n 1 | cut  -f 2 -d ' ') --build-arg cron_pattern="$(cron_pattern)" -t serlo/$(image) .

.PHONY: docker-run
# run docker container
docker_run:
	docker run --network=host -e KPI_DATABASE_HOST=$(shell minikube ip) --env-file docker.env --rm serlo/$(image):latest

	
