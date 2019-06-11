.PHONY: build
build:
	go build

.PHONY: run-once
run-once:
	go run *.go -- once

.PHONY: run-interval
run-interval:
	go run *.go -- run


.PHONY: docker-build
docker-build:
	docker build -t serlo/kpi-importer .
	docker tag serlo/kpi-importer:latest eu.gcr.io/serlo-containers/kpi-importer:latest

.PHONY: docker-push
docker-push:
	gcloud auth configure-docker
	docker push eu.gcr.io/serlo-containers/kpi-importer:latest

.PHONY: docker-run
docker-run:
	docker run --network=host -v $(CURDIR)/config.yaml:/app/config.yaml --rm serlo/kpi-importer -- once
