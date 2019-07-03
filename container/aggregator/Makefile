image_name=kpi-aggregator
local_image=serlo/$(image_name)

major_version=1
minor_version=2
patch_version=0
version=$(major_version).$(minor_version).$(patch_version) 

include ../../mk/dockerci.mk

cron_pattern=*/60 * * * *

.PHONY: docker_build
# build docker container
docker_build:
	docker build --build-arg git_revision=$(shell git log | head -n 1 | cut  -f 2 -d ' ') --build-arg cron_pattern="$(cron_pattern)" -t $(local_image) .

.PHONY: docker-run
# run docker container
docker_run:
	docker run --network=host -e KPI_DATABASE_HOST=$(shell minikube ip) --env-file docker.env --rm $(local_image):latest

	
