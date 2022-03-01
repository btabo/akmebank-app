FROM registry.access.redhat.com/ubi8/nodejs-16-minimal:1-14

USER root
WORKDIR "/tools"
ADD . /tools
RUN  npm install
ENV PATH="/tools:${PATH}"

ENTRYPOINT ["accounts"]

