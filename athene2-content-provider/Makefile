.PHONY: docker-build
docker-build:
	docker build -t serlo/kpi-athene2-content-provider .

.PHONY: docker-push
docker-push:
	docker tag serlo/kpi-athene2-content-provider:latest eu.gcr.io/serlo-containers/kpi-athene2-content-provider:latest
	docker push eu.gcr.io/serlo-containers/kpi-athene2-content-provider:latest
