image="athene2-dbsetup-cronjob"

#every hour check if database is empty after initial check
cron_pattern=0 0/1 * * *

.PHONY: build_image
build_image:
	docker images | grep $(image) && echo "image $(image) already exists use build_image_forced" || $(MAKE) docker_build

.PHONY: docker_build
# build the docker container
docker_build:
	docker build --build-arg git_revision=$(shell git log | head -n 1 | cut  -f 2 -d ' ') --build-arg cron_pattern="$(cron_pattern)" -t serlo/$(image) .

.PHONY: docker_push
# push the docker container to gcr repositoriy
docker_push:
	docker tag serlo/$(image):latest eu.gcr.io/serlo-containers/$(image):latest
	docker push eu.gcr.io/serlo-containers/$(image):latest
