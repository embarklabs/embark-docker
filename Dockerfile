# multi-stage builder images
# ------------------------------------------------------------------------------

ARG NODE_TAG=8.11.3-stretch
FROM node:${NODE_TAG} as builder-base

# ------------------------------------------------------------------------------

FROM builder-base as builder-geth
ARG GETH_VERSION=1.8.11-dea1ce05
RUN export url="https://gethstore.blob.core.windows.net/builds" \
    && export platform="geth-alltools-linux-amd64" \
    && curl -fsSLO --compressed "${url}/${platform}-${GETH_VERSION}.tar.gz" \
    && tar -xvzf geth-alltools* \
    && rm geth-alltools*/COPYING

# ------------------------------------------------------------------------------

FROM builder-base as builder-ipfs
ARG IPFS_VERSION=0.4.15
RUN export url="https://dist.ipfs.io/go-ipfs" \
    && export ver="v${IPFS_VERSION}/go-ipfs_v${IPFS_VERSION}" \
    && export platform="linux-amd64" \
    && curl -fsSLO --compressed "${url}/${ver}_${platform}.tar.gz" \
    && tar -xvzf go-ipfs*

# ------------------------------------------------------------------------------

FROM builder-base as builder-micro
ARG MICRO_VERSION=1.4.0
RUN export url="https://github.com/zyedidia/micro/releases/download" \
    && export ver="v${MICRO_VERSION}/micro-${MICRO_VERSION}" \
    && export platform="linux64" \
    && curl -fsSLO --compressed "${url}/${ver}-${platform}.tar.gz" \
    && tar -xvzf micro-${MICRO_VERSION}*

# ------------------------------------------------------------------------------

FROM builder-base as builder-suexec
ARG SUEXEC_VERSION=v0.2
RUN git clone --branch ${SUEXEC_VERSION} \
              --depth 1 \
              https://github.com/ncopa/su-exec.git 2> /dev/null \
    && cd su-exec \
    && make

# final image
# ------------------------------------------------------------------------------

FROM builder-base

LABEL maintainer="Andre Medeiros <andre@status.im>"

ARG __CODESET
ARG __LANG
ARG __LANGUAGE
ARG __LC_ALL
RUN export DEBIAN_FRONTEND=noninteractive \
    && apt-get update \
    && apt-get install -y locales \
    && export __CODESET=${__CODESET:-UTF-8} \
    && export __LANG=${__LANG:-en_US.$__CODESET} \
    && export __LANGUAGE=${__LANGUAGE:-en_US:en} \
    && export __LC_ALL=${__LC_ALL:-en_US.$__CODESET} \
    && sed -i \
           -e "s/# ${__LANG} ${__CODESET}/${__LANG} ${__CODESET}/" \
           /etc/locale.gen \
    && locale-gen --purge "${__LANG}" \
    && dpkg-reconfigure locales \
    && update-locale LANG=${__LANG} LANGUAGE=${__LANGUAGE} LC_ALL=${__LC_ALL} \
    && unset DEBIAN_FRONTEND \
    && rm -rf /var/lib/apt/lists/* \
    && adduser --disabled-password --shell /bin/bash --gecos "" embark \
    && mkdir -p /dapp \
    && chown embark:embark /dapp \
    && curl -fsSLO --compressed "https://bootstrap.pypa.io/get-pip.py" \
    && python get-pip.py \
    && rm get-pip.py

ENV LANG=${__LANG:-en_US.${__CODESET:-UTF-8}}
COPY --from=builder-ipfs /go-ipfs/ipfs /usr/local/bin/

USER embark
SHELL ["/bin/bash", "-c"]
WORKDIR /home/embark
COPY .bash_env \
     .bash_env_nvm_load \
     .bash_env_nvm_unload \
     .bashrc \
     .npmrc \
     ./
ARG EMBARK_VERSION=3.1.5
ARG GANACHE_VERSION=6.1.4
ARG NODEENV_VERSION=1.3.2
ARG NPM_VERSION=6.2.0
ARG NVM_VERSION=v0.33.11
RUN mkdir -p .npm-packages \
             .local/nodeenv \
    && . .bash_env \
    && pip install --user nodeenv==${NODEENV_VERSION} \
    && git clone --branch ${NVM_VERSION} \
                 --depth 1 \
                 https://github.com/creationix/nvm.git .nvm 2> /dev/null \
    && npm install -g "npm@${NPM_VERSION}" \
    && npm install -g "embark@${EMBARK_VERSION}" \
                      "ganache-cli@${GANACHE_VERSION}" \
    && ipfs init \
    && ipfs config --json Addresses.API '"/ip4/0.0.0.0/tcp/5001"' \
    && ipfs config --json Addresses.Gateway '"/ip4/0.0.0.0/tcp/8080"' \
    && ipfs config --json API.HTTPHeaders.Access-Control-Allow-Origin '["*"]' \
    && ipfs config --json API.HTTPHeaders.Access-Control-Allow-Methods '["GET", "POST", "PUT"]'

USER root
SHELL ["/bin/sh", "-c"]
WORKDIR /
COPY docker-entrypoint.sh \
     user-entrypoint.sh \
     install-extras.sh \
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
