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
.ONE_SHELL:
docker-build:
	docker build --build-arg git_revision=$(shell git log | head -n 1 | cut  -f 2 -d ' ') -t serlo/kpi-mysql-importer .

.PHONY: docker-push
docker-push:
	docker tag serlo/kpi-mysql-importer:latest eu.gcr.io/serlo-containers/kpi-mysql-importer:latest
	docker push eu.gcr.io/serlo-containers/kpi-mysql-importer:latest

.PHONY: docker-run
docker-run:
	docker run --network=host -v $(CURDIR)/config.yaml:/app/config.yaml --rm serlo/kpi-importer -- once
