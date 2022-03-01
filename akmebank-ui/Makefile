IMG ?= us.icr.io/paolo/akmebank-ui
TAG ?= 1.0.0

build:
	docker build -t ${IMG}:${TAG} .

push:
	docker push ${IMG}:${TAG}

run:
	npm run dev

deploy:
	sed "s|CLUSTER_NAMESPACE|${NS}|;s|IMAGE_AND_TAG|${IMG}:${TAG}|" k8s/deployment.yaml | kubectl apply -f -
	sed "s|CLUSTER_NAMESPACE|${NS}|;s|IMAGE_AND_TAG|${IMG}:${TAG}|" k8s/service.yaml | kubectl apply -f -

