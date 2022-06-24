FROM registry.access.redhat.com/ubi8/nodejs-16-minimal:latest

WORKDIR "/tools"

ADD . /tools

USER root

# https://security.snyk.io/vuln/SNYK-RHEL8-ZLIB-2434350
RUN microdnf -y update zlib

# Ensure js file (accounts) can be executed by any arbitrary UserIds
RUN chmod -R u+x /tools && \
    chgrp -R 0 /tools && \
    chmod -R g=u /tools

RUN  npm install
ENV PATH="/tools:${PATH}"

ENTRYPOINT ["accounts"]

