.PHONY: build
build:
	go build

image="kpi-mysql-importer"
cron_pattern=*/15 * * * *

.PHONY: build_image
build_image:
	docker images | grep $(image) && echo "image $(image) already exists use build_image_forced" || $(MAKE) docker_build

#
.PHONY: docker_build
.ONE_SHELL:
# build the docker container
docker_build:
	docker build --build-arg git_revision=$(shell git log | head -n 1 | cut  -f 2 -d ' ') --build-arg cron_pattern="$(cron_pattern)" -t serlo/$(image) .

.PHONY: docker_push
# tag and push the docker container to gcloud
docker_push:
	docker tag serlo/$(image):latest eu.gcr.io/serlo-containers/$(image):latest
	docker push eu.gcr.io/serlo-containers/$(image):latest

.PHONY: docker_run
# run the docker container agains databases in minikube
docker_run:
	sed "s/MINIKUBE_IP/$(shell minikube ip)/" config.yaml >config-minikube.yaml
	docker run --network=host -v $(CURDIR)/config-minikube.yaml:/app/config.yaml --rm serlo/$(image)
