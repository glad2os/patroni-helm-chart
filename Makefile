.PHONY: build image

build:
	helm package ./patroni-chart

image:
	docker buildx build -t glad2os/patroni:v0.0.2 --push -f ./docker/Dockerfile ./docker/
