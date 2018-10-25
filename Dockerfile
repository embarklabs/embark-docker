ARG __CODESET=UTF-8
ARG __LANGUAGE=en
ARG __REGION=US
ARG __LANG=${__LANGUAGE}_${__REGION}.${__CODESET}
ARG __LC_ALL=${__LANG}
ARG BASHIT_VERSION=10-aug-2018
ARG BUILDER_BASE_IMAGE=buildpack-deps
ARG BUILDER_BASE_TAG=stretch
ARG EMBARK_VERSION=latest
ARG GANACHE_VERSION=6.1.0
ARG GETH_VERSION=1.8.12-37685930
ARG IPFS_VERSION=0.4.17
ARG MICRO_VERSION=1.4.1
ARG NODE_VERSION=8.11.3
ARG NODEENV_VERSION=1.3.2
ARG NPM_VERSION=6.4.0
ARG NVM_VERSION=0.33.11
ARG SUEXEC_VERSION=0.2

# multi-stage builder images
# ------------------------------------------------------------------------------

FROM node:10.9.0-stretch as locales
# take the package specifier for embark_version and use `npm pack` to retrieve
# a tarball, unpack, and then process json file in embark that gives the
# supported locales and the default; use `npx json ...` to process into two
# files that can be easily read by bash; copy those files into builder-base
# (remaining steps are in the next builder image) and loop over the list of
# locales in the 'supported' file using the sed technique to uncomment in
# /etc/locale.gen, then run `dpkg-reconfigure locales`; in a later step use the
# info in the 'default' file as argumets for `update-locale` (unless builder
# args are defined, see below); the reason to prefer doing this w/ a node
# builder image vs. downloadig jq into builder-base (deleting jq at the end) is
# that `npm pack` is best suited to handling an EMBARK_VERSION value that could
# be any valid npm package specifier; once this is in place, probably still
# want to keep the __LANG (and related) builder args, but get rid of the
# default values, only do the sed step for them if they're defined; rather than
# setting ENV LANG, may prefer to do similar in docker-entrypoint based on the
# value in 'default' file (would need to copy it over), but only if it's not
# already defined, e.g. by it being forwarded with `docker run -e`, as run.sh
# does

# TODO make the nodez theme prettier by changing the color of the = and ver
# numbers to match the blue color used to report PWD

# ------------------------------------------------------------------------------

FROM ${BUILDER_BASE_IMAGE}:${BUILDER_BASE_TAG} as builder-base
ARG __CODESET
ARG __LANG
ARG __LANGUAGE
ARG __LC_ALL
SHELL ["/bin/bash", "-c"]
RUN export DEBIAN_FRONTEND=noninteractive \
    && apt-get update \
    && apt-get install -y less \
                          locales \
    && sed -i \
           -e "s/# ${__LANG} ${__CODESET}/${__LANG} ${__CODESET}/" \
           /etc/locale.gen \
    && dpkg-reconfigure locales \
    && update-locale LANG=${__LANG} LANGUAGE=${__LANGUAGE} LC_ALL=${__LC_ALL} \
    && unset DEBIAN_FRONTEND \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /usr/share/terminfo/d \
    && ln -s /lib/terminfo/d/dumb /usr/share/terminfo/d/dumb
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

ARG BASHIT_VERSION
ARG EMBARK_VERSION
ARG GANACHE_VERSION
ARG NODE_VERSION
ARG NODEENV_VERSION
ARG NPM_VERSION
ARG NVM_VERSION
SHELL ["/bin/bash", "-c"]
RUN adduser --disabled-password --shell /bin/bash --gecos "" embark \
    && usermod -a -G tty embark \
    && mkdir -p /dapp \
    && chown embark:embark /dapp \
    && curl -fsSLO --compressed "https://bootstrap.pypa.io/get-pip.py" \
    && python get-pip.py \
    && rm get-pip.py

COPY --from=builder-ipfs /go-ipfs/ipfs /usr/local/bin/
USER embark
WORKDIR /home/embark
RUN git clone --branch ${BASHIT_VERSION} \
              --depth 1 \
              https://github.com/michaelsbradleyjr/bash-it.git \
              .bash_it 2> /dev/null \
    && mkdir -p .bash_it/custom/themes/nodez \
    && git clone --branch v${NVM_VERSION} \
                 --depth 1 \
                 https://github.com/creationix/nvm.git \
                 .nvm 2> /dev/null \
    && export PATH=${HOME}/.local/bin:$PATH \
    && pip install --user nodeenv==${NODEENV_VERSION} \
    && mkdir -p .local/nodeenv \
    && nodeenv --prebuilt \
               --node ${NODE_VERSION} \
               .local/nodeenv/default \
    && . .local/nodeenv/default/bin/activate \
    && npm install -g "npm@${NPM_VERSION}" \
    && npm install -g "embark@${EMBARK_VERSION}" \
                      "ganache-cli@${GANACHE_VERSION}" \
    && ipfs init \
    && ipfs config --json Addresses.API '"/ip4/0.0.0.0/tcp/5001"' \
    && ipfs config --json Addresses.Gateway '"/ip4/0.0.0.0/tcp/8080"' \
    && ipfs config --json API.HTTPHeaders.Access-Control-Allow-Origin '["*"]' \
    && ipfs config --json API.HTTPHeaders.Access-Control-Allow-Methods '["GET", "POST", "PUT"]'

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
    BASHIT_VERSION=${BASHIT_VERSION} \
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
USER root
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
COPY env/docker-entrypoint.sh \
     env/user-entrypoint.sh \
     env/install-extras.sh \
     /usr/local/bin/
COPY --chown=embark:embark \
     env/.bash_env \
     env/.bash_env_nodeenv_exports \
     env/.bash_env_unset_npm_config \
     env/.bashrc \
     env/.npmrc \
     /home/embark/
COPY --chown=embark:embark \
     env/nodez.theme.bash \
     /home/embark/.bash_it/custom/themes/nodez/
