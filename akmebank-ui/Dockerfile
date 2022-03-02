FROM registry.access.redhat.com/ubi8/nodejs-16-minimal:1-14

# https://access.redhat.com/errata/RHSA-2022:0658
RUN dnf --assumeyes --best install cyrus-sasl

USER root
WORKDIR "/app"
ADD . /app
RUN  npm install
ENV PATH="/app:${PATH}"

ENTRYPOINT ["npm","start"]

