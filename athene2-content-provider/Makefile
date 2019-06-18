.PHONY: docker-build
docker-build:
	docker build --build-arg git_revision=$(shell git log | head -n 1 | cut  -f 2 -d ' ') -t serlo/kpi-athene2-content-provider .

.PHONY: docker-push
docker-push:
	docker tag serlo/kpi-athene2-content-provider:latest eu.gcr.io/serlo-containers/kpi-athene2-content-provider:latest
	docker push eu.gcr.io/serlo-containers/kpi-athene2-content-provider:latest
