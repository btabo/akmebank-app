IMG ?= us.icr.io/paolo/account-command-ms
TAG ?= 1.0.0
NS ?=thinkdemo
MVN_LOCAL_REPO ?= ~/.m2/repository

test:
	mvn test

build:
	cd .. && mvn install -Dmaven.repo.local=${MVN_LOCAL_REPO} -DskipTests
	mvn package -Dmaven.repo.local=${MVN_LOCAL_REPO} -DskipTests
	docker build -f src/main/docker/Dockerfile.jvm -t ${IMG}:${TAG} .

push:
	docker push ${IMG}:${TAG}

run:
	./mvnw compile quarkus:dev: -Ddebug=5005

deploy:
	sed "s|IMAGE_AND_TAG|${IMG}:${TAG}|" k8s/deployment.yaml | kubectl apply -n${NS} -f -
	kubectl apply -n${NS} -f k8s/service.yaml

create-cos-secret:
	kubectl create secret generic cos-secret \
	--from-literal=API_KEY=${API_KEY} \
	--from-literal=SERVICE_INSTANCE_ID=${SERVICE_INSTANCE_ID} \
	--from-literal=ENDPOINT_URL=${ENDPOINT_URL} \
	--from-literal=LOCATION=${LOCATION} \
	--from-literal=ACCOUNTS_BUCKET=${ACCOUNTS_BUCKET} \
	--from-literal=USERS_BUCKET=${USERS_BUCKET}
