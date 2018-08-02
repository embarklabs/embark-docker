FROM node:8.11.3-stretch

MAINTAINER Andre Medeiros <andre@status.im>

ENV EMBARK_VERSION=3.1.5 \
    GANACHE_VERSION=6.1.4 \
    GETH_VERSION=1.8.11-dea1ce05 \
    IPFS_VERSION=0.4.15

# IPFS: 5001 8080
# Go Ethereum: 30303/tcp 30301/udp 8545
# Embark: 8000 8546 8545
# Swarm: 8500
EXPOSE 5001 8080 30303/tcp 30301/udp 8545 8546 8000 8500

RUN adduser --disabled-password --shell /bin/bash --gecos "" embark \
    # Install geth
    && curl -fsSLO --compressed "https://gethstore.blob.core.windows.net/builds/geth-alltools-linux-amd64-${GETH_VERSION}.tar.gz" \
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
    && rm -rf "geth-alltools-linux-amd64-${GETH_VERSION}"* \
    # Install ipfs
    && curl -fsSLO --compressed "https://dist.ipfs.io/go-ipfs/v${IPFS_VERSION}/go-ipfs_v${IPFS_VERSION}_linux-amd64.tar.gz" \
    && tar -xvzf "go-ipfs_v${IPFS_VERSION}_linux-amd64.tar.gz" \
    && cp go-ipfs/ipfs /usr/local/bin/ipfs \
    && rm -rf go-ipfs "go-ipfs_v${IPFS_VERSION}_linux-amd64.tar.gz" \
    && mkdir /dapp \
    && chown embark:embark /dapp

USER embark

RUN mkdir /home/embark/.npm-packages \
    && echo prefix=/home/embark/.npm-packages > /home/embark/.npmrc \
    && for directive in \
      "export NPM_PACKAGES=\$HOME/.npm-packages" \
      "export NODE_PATH=\$NPM_PACKAGES/lib/node_modules:\$NODE_PATH" \
      "export PATH=\$NPM_PACKAGES/bin:\$PATH" \
    ; do \
      echo ${directive} >> /home/embark/.profile \
      && echo ${directive} >> /home/embark/.bashrc; \
    done \
    # Ensure we source the updated bashrc
    && . ~/.bashrc \
    # Install embark and the simulator
    && npm install -g "embark@${EMBARK_VERSION}" "ganache-cli@${GANACHE_VERSION}" \
    # Initialize IPFS
    && ipfs init \
    # Cleanup build stuff
    && echo "Done"

WORKDIR /dapp

CMD ["embark"]

