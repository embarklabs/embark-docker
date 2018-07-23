FROM node:8.11.3-stretch

MAINTAINER Andre Medeiros <andre@status.im>

# Embark: 8000 8545 8546
# Go Ethereum: 30301/udp 30303 8545 8546 (when proxied: 8555 8556)
# IPFS: 5001 8080
# Swarm: 8500
EXPOSE 5001 8000 8080 8500 8545 8546 8555 8556 30301/udp 30303

ARG SUEXEC_VERSION
ENV SUEXEC_VERSION=${SUEXEC_VERSION:-v0.2}
# Install su-exec
RUN cd /tmp \
    && git clone --branch ${SUEXEC_VERSION} --depth 1 \
       https://github.com/ncopa/su-exec.git 2> /dev/null \
    && cd su-exec \
    && make \
    && cp su-exec /usr/local/bin/ \
    && cd .. \
    && rm -rf su-exec

ARG GETH_VERSION
ENV GETH_VERSION=${GETH_VERSION:-1.8.11-dea1ce05}
# Install geth
RUN curl -fsSLO --compressed "https://gethstore.blob.core.windows.net/builds/geth-alltools-linux-amd64-${GETH_VERSION}.tar.gz" \
    && tar -xvzf "geth-alltools-linux-amd64-${GETH_VERSION}.tar.gz" \
    && for geth_tool in \
      abigen \
      bootnode \
      evm \
      geth \
      puppeth \
      rlpdump \
      swarm \
      wnode \
    ; do \
      cp "geth-alltools-linux-amd64-${GETH_VERSION}/${geth_tool}" "/usr/local/bin/${geth_tool}"; \
    done \
    && rm -rf "geth-alltools-linux-amd64-${GETH_VERSION}*"

ARG IPFS_VERSION
ENV IPFS_VERSION=${IPFS_VERSION:-0.4.15}
# Install ipfs
RUN curl -fsSLO --compressed "https://dist.ipfs.io/go-ipfs/v${IPFS_VERSION}/go-ipfs_v${IPFS_VERSION}_linux-amd64.tar.gz" \
    && tar -xvzf "go-ipfs_v${IPFS_VERSION}_linux-amd64.tar.gz" \
    && cp go-ipfs/ipfs /usr/local/bin/ipfs \
    && rm -rf go-ipfs "go-ipfs_v${IPFS_VERSION}_linux-amd64.tar.gz"

# Install pip
RUN curl -fsSLO --compressed "https://bootstrap.pypa.io/get-pip.py" \
    && python get-pip.py \
    && rm get-pip.py

# Setup unprivileged user
RUN adduser --disabled-password --shell /bin/bash --gecos "" embark \
    && mkdir -p /dapp \
    && mkdir -p /home/embark/.npm-packages \
    && chown embark:embark /dapp /home/embark/.npm-packages
COPY dot.bash_env /home/embark/.bash_env
COPY dot.bash_env_nvm_load /home/embark/.bash_env_nvm_load
COPY dot.bash_env_nvm_unload /home/embark/.bash_env_nvm_unload
COPY dot.bashrc /home/embark/.bashrc
COPY dot.npmrc /home/embark/.npmrc
RUN chown embark:embark /home/embark/.bash_env \
    && chown embark:embark /home/embark/.bashrc \
    && chown embark:embark /home/embark/.npmrc

ARG EMBARK_VERSION
ARG GANACHE_VERSION
ARG NODEENV_VERSION
ARG NVM_VERSION
ENV EMBARK_VERSION=${EMBARK_VERSION:-3.1.5}
ENV GANACHE_VERSION=${GANACHE_VERSION:-6.1.4}
ENV NODEENV_VERSION=${NODEENV_VERSION:-1.3.2}
ENV NVM_VERSION=${NVM_VERSION:-v0.33.11}
# Install tooling and Embark Framework
USER embark
SHELL ["/bin/bash", "-c"]
WORKDIR /home/embark
RUN . ${HOME}/.bash_env \
    && git clone --branch ${NVM_VERSION} --depth 1 \
       https://github.com/creationix/nvm.git .nvm 2> /dev/null \
    && pip install --user nodeenv==${NODEENV_VERSION} \
    && mkdir -p ${HOME}/.local/nodeenv \
    && npm install -g "ganache-cli@${GANACHE_VERSION}" \
    && npm install -g "embark@${EMBARK_VERSION}" \
    # Initialize IPFS
    && ipfs init \
    && ipfs config --json Addresses.API '"/ip4/0.0.0.0/tcp/5001"' \
    && ipfs config --json Addresses.Gateway '"/ip4/0.0.0.0/tcp/8080"' \
    && ipfs config --json API.HTTPHeaders.Access-Control-Allow-Origin '["*"]' \
    && ipfs config --json API.HTTPHeaders.Access-Control-Allow-Methods '["GET", "POST", "PUT"]'

# Setup entrypoint and default working directory
USER root
SHELL ["/bin/sh", "-c"]
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["bash"]
WORKDIR /dapp
