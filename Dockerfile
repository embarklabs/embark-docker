ARG __CODESET=UTF-8
ARG __LANG=en_US.${__CODESET}
ARG __LANGUAGE=en_US:en
ARG __LC_ALL=en_US.${__CODESET}
ARG BUILDER_BASE_IMAGE=buildpack-deps
ARG BUILDER_BASE_TAG=stretch
ARG EMBARK_VERSION=3.1.5
ARG GANACHE_VERSION=6.1.4
ARG GETH_VERSION=1.8.11-dea1ce05
ARG IPFS_VERSION=0.4.15
ARG MICRO_VERSION=1.4.0
ARG NODE_VERSION=8.11.3
ARG NODEENV_VERSION=1.3.2
ARG NPM_VERSION=6.2.0
ARG NVM_VERSION=0.33.11
ARG SUEXEC_VERSION=0.2

# multi-stage builder images
# ------------------------------------------------------------------------------

FROM ${BUILDER_BASE_IMAGE}:${BUILDER_BASE_TAG} as builder-base
ARG __CODESET
ARG __LANG
ARG __LANGUAGE
ARG __LC_ALL
SHELL ["/bin/bash", "-c"]
RUN export DEBIAN_FRONTEND=noninteractive \
    && apt-get update \
    && apt-get install -y locales \
    && sed -i \
           -e "s/# ${__LANG} ${__CODESET}/${__LANG} ${__CODESET}/" \
           /etc/locale.gen \
    && locale-gen --purge "${__LANG}" \
    && dpkg-reconfigure locales \
    && update-locale LANG=${__LANG} LANGUAGE=${__LANGUAGE} LC_ALL=${__LC_ALL} \
    && unset DEBIAN_FRONTEND \
    && rm -rf /var/lib/apt/lists/*
ENV LANG=${__LANG}
SHELL ["/bin/sh", "-c"]

# ------------------------------------------------------------------------------

FROM builder-base as builder-geth
ARG GETH_VERSION
RUN export url="https://gethstore.blob.core.windows.net/builds" \
    && export platform="geth-alltools-linux-amd64" \
    && curl -fsSLO --compressed "${url}/${platform}-${GETH_VERSION}.tar.gz" \
    && tar -xvzf geth-alltools* \
    && rm geth-alltools*/COPYING

# ------------------------------------------------------------------------------

FROM builder-base as builder-ipfs
ARG IPFS_VERSION
RUN export url="https://dist.ipfs.io/go-ipfs" \
    && export ver="v${IPFS_VERSION}/go-ipfs_v${IPFS_VERSION}" \
    && export platform="linux-amd64" \
    && curl -fsSLO --compressed "${url}/${ver}_${platform}.tar.gz" \
    && tar -xvzf go-ipfs*

# ------------------------------------------------------------------------------

FROM builder-base as builder-micro
ARG MICRO_VERSION
RUN export url="https://github.com/zyedidia/micro/releases/download" \
    && export ver="v${MICRO_VERSION}/micro-${MICRO_VERSION}" \
    && export platform="linux64" \
    && curl -fsSLO --compressed "${url}/${ver}-${platform}.tar.gz" \
    && tar -xvzf micro-${MICRO_VERSION}*

# ------------------------------------------------------------------------------

FROM builder-base as builder-suexec
ARG SUEXEC_VERSION
RUN git clone --branch v${SUEXEC_VERSION} \
              --depth 1 \
              https://github.com/ncopa/su-exec.git 2> /dev/null \
    && cd su-exec \
    && make

# final image
# ------------------------------------------------------------------------------

FROM builder-base

LABEL maintainer="Andre Medeiros <andre@status.im>"

    && adduser --disabled-password --shell /bin/bash --gecos "" embark \
ARG EMBARK_VERSION
ARG GANACHE_VERSION
ARG NODE_VERSION
ARG NODEENV_VERSION
ARG NPM_VERSION
ARG NVM_VERSION
    && mkdir -p /dapp \
    && chown embark:embark /dapp \
    && curl -fsSLO --compressed "https://bootstrap.pypa.io/get-pip.py" \
    && python get-pip.py \
    && rm get-pip.py

COPY --from=builder-ipfs /go-ipfs/ipfs /usr/local/bin/

USER embark
SHELL ["/bin/bash", "-c"]
WORKDIR /home/embark
COPY --chown=embark:embark \
     env/.bash_env \
     env/.bash_env_nvm_load \
     env/.bash_env_nvm_unload \
     env/.bashrc \
     env/.npmrc \
     ./
RUN mkdir -p .npm-packages \
             .local/nodeenv \
    && . .bash_env \
    && pip install --user nodeenv==${NODEENV_VERSION} \
    && git clone --branch ${NVM_VERSION} \
                 --depth 1 \
                 https://github.com/creationix/nvm.git .nvm 2> /dev/null \
    && . .nvm/nvm.sh \
    && nvm install v${NODE_VERSION} \
    && npm install -g "npm@${NPM_VERSION}" \
    && npm install -g "embark@${EMBARK_VERSION}" \
                      "ganache-cli@${GANACHE_VERSION}" \
    && ipfs init \
    && ipfs config --json Addresses.API '"/ip4/0.0.0.0/tcp/5001"' \
    && ipfs config --json Addresses.Gateway '"/ip4/0.0.0.0/tcp/8080"' \
    && ipfs config --json API.HTTPHeaders.Access-Control-Allow-Origin '["*"]' \
    && ipfs config --json API.HTTPHeaders.Access-Control-Allow-Methods '["GET", "POST", "PUT"]'

USER root
ARG __CODESET
ARG __LANG
ARG __LANGUAGE
ARG __LC_ALL
ARG BUILDER_BASE_IMAGE
ARG BUILDER_BASE_TAG
ARG GETH_VERSION
ARG IPFS_VERSION
ARG MICRO_VERSION
ARG SUEXEC_VERSION
ENV __CODESET=${__CODESET} \
    __LANG=${__LANG} \
    __LANGUAGE=${__LANGUAGE} \
    __LC_ALL=${__LC_ALL} \
    BUILDER_BASE_IMAGE=${BUILDER_BASE_IMAGE} \
    BUILDER_BASE_TAG=${BUILDER_BASE_TAG} \
    EMBARK_VERSION=${EMBARK_VERSION} \
    GANACHE_VERSION=${GANACHE_VERSION} \
    GETH_VERSION=${GETH_VERSION} \
    IPFS_VERSION=${IPFS_VERSION} \
    MICRO_VERSION=${MICRO_VERSION} \
    NODEENV_VERSION=${NODEENV_VERSION} \
    NVM_VERSION=${NVM_VERSION} \
    SUEXEC_VERSION=${SUEXEC_VERSION}
SHELL ["/bin/sh", "-c"]
WORKDIR /
COPY env/docker-entrypoint.sh \
     env/user-entrypoint.sh \
     env/install-extras.sh \
     /usr/local/bin/

WORKDIR /dapp
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["embark", "run"]
# Embark: 8000 8545 8546
# Go Ethereum: 30301/udp 30303 8545 8546 (when proxied: 8555 8556)
# IPFS: 5001 8080
# Swarm: 8500
EXPOSE 5001 8000 8080 8500 8545 8546 8555 8556 30301/udp 30303

COPY --from=builder-geth /geth-alltools* /usr/local/bin/
COPY --from=builder-micro /micro*/micro /usr/local/bin/
COPY --from=builder-suexec /su-exec/su-exec /usr/local/bin/
