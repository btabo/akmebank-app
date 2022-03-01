IMG ?= us.icr.io/paolo/account-cli
TAG ?= latest

build:
	docker build -t ${IMG}:${TAG} .

push:
	docker push ${IMG}:${TAG}