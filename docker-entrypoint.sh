#!/bin/bash

export BASH_ENV=/home/embark/.bash_env

chmod a+w /dev/std*
exec su-exec embark user-entrypoint.sh "$@"
