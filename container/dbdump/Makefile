image=athene2-dbdump-cronjob

#run only at 4 am
cron_pattern=0 4 * * *

.PHONY: build_image
build_image:
	docker images | grep $(image) && echo "image $(image) already exists use build_image_forced" || $(MAKE) docker_build

.PHONY: docker_build
docker_build:
	docker build --build-arg git_revision=$(shell git log | head -n 1 | cut  -f 2 -d ' ') --build-arg cron_pattern="$(cron_pattern)" -t serlo/$(image) .

docker_run:
	docker run \
	    --network=host \
		-e ATHENE2_DATABASE_HOST=$(shell minikube ip) \
		-e ATHENE2_DATABASE_PORT=30020 \
		-e ATHENE2_DATABASE_USER=root \
		-e ATHENE2_DATABASE_PASSWORD=admin \
		-e ENVIRONMENT=docker \
		-it serlo/$(image):latest

.PHONY: docker_push
docker_push:
	docker tag serlo/$(image):latest eu.gcr.io/serlo-containers/$(image):latest
	docker push eu.gcr.io/serlo-containers/$(image):latest
