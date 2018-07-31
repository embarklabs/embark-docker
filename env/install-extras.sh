#!/bin/bash

apt-get update
apt-get install -y \
        less \
        lsof \
        net-tools \
        parallel \
        silversearcher-ag \
        tmux \
        vim

echo will cite | parallel --bibtex >/dev/null
