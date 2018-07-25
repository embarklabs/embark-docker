# Embark for Docker

## Quick start

In a Bash shell:
``` shell
source <(curl 'https://raw.githubusercontent.com/embark-framework/embark-docker/master/run.sh')
run_embark demo
cd embark_demo
run_embark
```

With overrides:

``` shell
export EMBARK_DOCKER_EXTRA_RUN_OPTS='--rm'
export EMBARK_DOCKER_IMAGE=statusim/embark
export EMBARK_DOCKER_TAG=custom
export EMBARK_DOCKERFILE='https://github.com/embark-framework/embark-docker.git#some/branch'
export EMBARK_VERSION='embark-framework/embark#features/branch'
export NODE_TAG=10.7.0
export RUNNER='https://raw.githubusercontent.com/embark-framework/embark-docker/some/branch/run.sh'

docker build \
       --build-arg EMBARK_VERSION=$EMBARK_VERSION \
       --build-arg NODE_TAG=$NODE_TAG \
       -t $EMBARK_DOCKER_IMAGE:$EMBARK_DOCKER_TAG \
       $EMBARK_DOCKERFILE

source <(curl $RUNNER)
run_embark demo
cd embark_demo
run_embark
```

Review the
[Dockerfile](https://github.com/embark-framework/embark-docker/blob/master/Dockerfile)
and
[run.sh](https://github.com/embark-framework/embark-docker/blob/master/run.sh#L66-L70)
for all possible overrides.

### Shortcuts

These are equivlent:

``` shell
run_embark
```
``` shell
run_embark run
```
``` shell
run_embark embark run
```

The following are also equivalent:

``` shell
run_embark demo
```
``` shell
run_embark embark demo
```

The same is true for the rest of the `embark` commands. To see the full list:

``` shell
run_embark --help
```

### Compound commands

A single command with options can be supplied directly:

``` shell
run_embark bash
```
``` shell
run_embark ps -ef
```

Compound commands should be passed to `bash -[i]c`:

``` shell
run_embark bash -c 'exec bash << "SCRIPT"

simple_nodeenv 10.7.0 my_node
node --version
echo $(which node)
npm i -g http-server
exec http-server -p 10000

SCRIPT
'
```

When executing compound commands via `docer exec` in a running embark
container, `su-exec` and `bash -ic` can be used together:

``` shell
docker exec -it <container-id> su-exec embark \
       bash -ic 'exec bash << "SCRIPT"

nac my_node
exec http-server -p 10001

SCRIPT
'
```

Alternatively, to go non-interactive, manually source the embark user's
`.bash_env`:

``` shell
docker exec -it <container-id> su-exec embark \
       bash -c 'exec bash << "SCRIPT"

. ~/.bash_env
nvm_load no-auto-lts
nvm install v10.6.0
echo $(which node)
npm i -g http-server
exec http-server -p 10002

SCRIPT
'
```

## Updating versions

* Open `Dockerfile`
* On the `ARG` directives, update necessary versions.

## Building

Building requires Docker to be installed on your local machine.

### Scripted

If you have Ruby installed in your system, run:

```
$ ruby script/build
```

To release, add `--release` as a parameter of the build script.

### Manually

Building and releasing manually isn't too hard either, but there are a couple
steps.

#### Tags

To facilitate the images being found, we tag them with the following rules (as
an example, the `3.1.5` version will be used.)

- Tag with `statusim/embark:latest` if `3.1.5` is the latest version.
- Tag with `statusim/embark:3.1.5`
- Tag with `statusim/embark:3.1` if `3.1.5` is the highest patch level on `3.1`
- Tag with `statusim/embark:3` if `3.1.5` is the highest minor and patch level
  on `3`

#### Generating the image

To generate the image, run:

```
docker build . -t statusim/embark:<version> [...tags]
```

## Releasing

Releasing requires that you're authenticated to Docker Hub. To do so, run:

```
$ docker login
```

### Scripted

If you have Ruby installed in your system, run:

```
$ ruby script/build --release
```

### Manual

Pushing the tags manually implies that the image has been previously built. To
push your local images, run:

```
docker push statusim/embark:version
```
