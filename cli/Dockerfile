FROM registry.access.redhat.com/ubi8/nodejs-16-minimal:1-14.1645811213

WORKDIR "/tools"

ADD . /tools

USER root

# Ensure js file (accounts) can be executed by any arbitrary UserIds
RUN chmod -R u+x /tools && \
    chgrp -R 0 /tools && \
    chmod -R g=u /tools

RUN  npm install
ENV PATH="/tools:${PATH}"

ENTRYPOINT ["accounts"]

