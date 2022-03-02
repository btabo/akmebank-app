FROM registry.access.redhat.com/ubi8/nodejs-16-minimal:1-1-36.1645811220

USER root
WORKDIR "/app"
ADD . /app
RUN  npm install
ENV PATH="/app:${PATH}"

ENTRYPOINT ["npm","start"]

