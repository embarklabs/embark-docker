#!/bin/bash

export BASH_ENV=/home/embark/.bash_env

chmod a+w /dev/std*
chmod g+r /dev/pts/0
exec su-exec embark user-entrypoint.sh "$@"
