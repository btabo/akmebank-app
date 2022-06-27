FROM registry.access.redhat.com/ubi8/nodejs-16-minimal:latest

USER root

RUN microdnf update -y && microdnf upgrade -y

# https://security.snyk.io/vuln/SNYK-RHEL8-ZLIB-2434350
RUN microdnf -y update zlib

WORKDIR "/app"
ADD . /app
RUN  npm install
ENV PATH="/app:${PATH}"

# TODO - remove - for debugging only
RUN node --version
RUN npm --version
ENTRYPOINT ["npm","start"]

