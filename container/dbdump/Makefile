image_name=athene2-dbdump-cronjob
local_image=serlo/$(image_name)

major_version=1
minor_version=0
#patch version is automatically generated from minor_version + number of commits so we do not need to maintain it

include ../../mk/dockerci.mk

#run only at 4 am
cron_pattern=0 4 * * *

.PHONY: build_image
build_image:
	docker images | grep $(local_image) && echo "image $(local_image) already exists use build_image_forced" || $(MAKE) docker_build

.PHONY: docker_build
docker_build:
	docker build --build-arg git_revision=$(shell git log | head -n 1 | cut  -f 2 -d ' ') --build-arg cron_pattern="$(cron_pattern)" -t $(local_image) .

docker_run:
	docker run \
	    --network=host \
		-e ATHENE2_DATABASE_HOST=$(shell minikube ip) \
		-e ATHENE2_DATABASE_PORT=30020 \
		-e ATHENE2_DATABASE_USER=root \
		-e ATHENE2_DATABASE_PASSWORD=admin \
		-e ENVIRONMENT=docker \
		-it $(local_image):latest

