image_name="athene2-dbsetup-cronjob"
local_image=serlo/$(image_name)

major_version=1
minor_version=0
#patch version is automatically generated from minor_version + number of commits so we do not need to maintain it

include ../../mk/dockerci.mk

#every hour check if database is empty after initial check
cron_pattern=0 0/1 * * *

.PHONY: build_image
build_image:
	docker images | grep $(local_image) && echo "image $(local_image) already exists use build_image_forced" || $(MAKE) docker_build

.PHONY: docker_build
# build the docker container
docker_build:
	docker build --build-arg git_revision=$(shell git log | head -n 1 | cut  -f 2 -d ' ') --build-arg cron_pattern="$(cron_pattern)" -t $(local_image) .

