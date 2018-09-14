# Embark for Docker

## Quick start

In a Bash shell:
``` shell
source <(curl -L https://bit.ly/run_embark)
run_embark demo
cd embark_demo
run_embark
```

Note that the `run_embark demo` command will create an `embark_demo` directory in
the docker host's `$PWD`.

Note if you receive the error `ERROR: this script requires Bash version >= 4.0` on macOS, follow the steps below:
1. Install HomeBrew (if not already installed):
`ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"`
2. Update homebrew packet database and install bash:
`brew update && brew install bash`
3. Change your application to use the correct shell. For example, in Terminal, open Preferences, then change "Shells open with:" to "/usr/local/bin/bash":
![Terminal preferences](https://i.imgur.com/vDWQfO7.png)
In iTerm2, change Preferences > Profiles > (Select profile) > General > Command > Command to `/usr/local/bin/bash`:
![iTerm2 preferences](https://i.imgur.com/zUZE663.png)
4. `bash --version` should show version 4+:
`$ bash --version`
`GNU bash, version 4.4.23(1)-release (x86_64-apple-darwin17.5.0)
Copyright (C) 2016 Free Software Foundation, Inc.
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>`
5. There is a [guide to upgrading to bash 4 in macOS](http://clubmate.fi/upgrade-to-bash-4-in-mac-os-x/) if you need more help.

## Usage via `run.sh`

[`run.sh`](https://github.com/embark-framework/embark-docker/blob/master/run.sh)
is a Bash script that simplifies usage of the embark container: publishing
ports, bind mounting a host volume, and so on.

When sourced, `run.sh` makes available a shell function named
`run_embark`. When executed, `run.sh` forwards its arguments to the
`run_embark` shell function.

Many aspects of `run_embark`'s behavior can be overridden with environment
variables, and that approach can be (optionally) combined with `docker build`.

``` shell
EMBARK_DOCKER_IMAGE=statusim/embark
EMBARK_DOCKER_TAG=develop
EMBARK_DOCKERFILE='https://github.com/embark-framework/embark-docker.git#master'
EMBARK_VERSION='embark-framework/embark#develop'
NODE_VERSION=10.7.0
RUNNER='https://raw.githubusercontent.com/embark-framework/embark-docker/master/run.sh'

docker build \
       --build-arg EMBARK_VERSION=$EMBARK_VERSION \
       --build-arg NODE_VERSION=$NODE_VERSION \
       -t $EMBARK_DOCKER_IMAGE:$EMBARK_DOCKER_TAG \
       $EMBARK_DOCKERFILE

source <(curl $RUNNER)
run_embark demo
cd embark_demo
run_embark
```

Review the
[`Dockerfile`](https://github.com/embark-framework/embark-docker/blob/master/Dockerfile)
and
[`run.sh`](https://github.com/embark-framework/embark-docker/blob/master/run.sh)
for all possible overrides.

It's possible to pass additional options to `docker run` by specifying them
before `--`.

``` shell
run_embark [docker-run-opts] -- [command]
```

To completely replace the default `docker run` options:

``` shell
EMBARK_DOCKER_RUN_OPTS_REPLACE=true
run_embark [docker-run-opts] -- [command]
```

By default `run_embark` invokes `docker run` with the
[`--rm`](https://docs.docker.com/engine/reference/run/#clean-up---rm) option,
making the embark container ephemeral, i.e. it will not persist on the docker
host's file system after the container exits. To override this behavior:

``` shell
EMBARK_DOCKER_RUN_RM=false
run_embark [docker-run-opts] -- [command]
```

Note that if you have `EMBARK_DOCKER_RUN_OPTS_REPLACE=true`, then `--rm` would
need to be provided in `[docker-run-opts]`, i.e. `EMBARK_DOCKER_RUN_RM` will be
effectively ignored.

### Shortcuts

These are equivalent:

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

### Utilities

The container comes equipped with
[`nodeenv`](https://github.com/ekalinin/nodeenv) and
[`nvm`](https://github.com/creationix/nvm). A `default` Node.js environment is
installed via `nodeenv` during image build and placed in
`~embark/.local/nodeenv/default`. The `default` environment is automatically
activated by the container's entrypoint.

Both `nodeenv` and `nvm` can be used in
interactive and non-interactive scripts.

#### `nodeenv`

These are equivalent:

``` shell
nodeenv --prebuilt --node 10.7.0 ~/.local/nodeenv/my_node
```
``` shell
simple_nodeenv 10.7.0 my_node
```

Activate and deactivate environments with `nac` and `denac`.

``` shell
nac my_node
```
``` shell
denac
```

Note that `simple_nodeenv` automatically activates an environment after
installation, while `nodeenv` does not.

#### `nvm`

If `nvm` is preferable, it needs to be loaded first.

``` shell
nvm_load
nvm install --latest-npm 8.11.3
```

`nvm deactivate` and `nvm unload` will work as expected. It's also possible to
move between `nodeenv` and `nvm` environments without first deactivating or
unloading.

``` shell
nac default
nvm_load && nvm use v10.7.0
# ^ assuming 10.7.0 is already installed
nac default
```

#### `micro`

The [`micro`](https://github.com/zyedidia/micro) editor is installed during image
build, should you need to edit files within a running container.

#### `install-extras.sh`

Some nice-to-have utilities are not installed by default, but this can be done
by running
[`install-extras.sh`](https://github.com/embark-framework/embark-docker/blob/master/env/install-extras.sh)
as the `root` user in an already running container.

``` shell
docker exec -it $container_id install-extras.sh
```

### Commands

#### Simple

A single command with options can be supplied directly.

``` shell
run_embark bash
```
``` shell
run_embark node -i -e 'console.log(process.version)'
# ^ press return again to get a blank REPL prompt
```
``` shell
run_embark ps -ef
```

#### Compound

Compound commands should be passed to `bash -[i]c`.

``` shell
run_embark bash -c 'ps -ef && ls / ; which embark'
```
``` shell
run_embark bash -c 'nvm_load && nvm install --latest-npm 8.11.3 && node --version && npm --version'
```

Bash
[here-documents](https://www.gnu.org/software/bash/manual/html_node/Redirections.html#Here-Documents)
can be used to compose scripts without employing an abundance of `&&`, `;`, and
`\`. Just be mindful of umatched quotes and quotes-escaping when building
meta-scripts; in such scenarios, use of
[`envsubst`](https://www.gnu.org/software/gettext/manual/html_node/envsubst-Invocation.html)
is probably called for.

``` shell
run_embark bash -c 'exec bash << "SCRIPT"

simple_nodeenv 10.7.0 my_node
npm i -g http-server
exec http-server -p 8000

SCRIPT
'
```

Since `run_embark` mounts the docker host's `$PWD` into the container's `/dapp`, and
since `/dapp` is the container's default working directory, it's also possible
to do:

``` shell
run_embark ./my_script.sh
# ^ assuming my_script.sh is in the docker host's $PWD
```

Just make sure the script has a `#!` line and that you did `chmod +x
my_script.sh` on the docker host before invoking `run_embark`.

##### `$EMBARK_DOCKER_RUN`

For greater flexibility, you can specify a script with
`$EMBARK_DOCKER_RUN`. Arguments passed to `run_embark` will be forwarded to the
script, and extra flags can be provided to `docker run` to forward docker host
environment variables.

Keep in mind that such scripts will run as the `embark` user owing to the
container's entrypoint.

``` shell
#!/bin/bash
# this script is located at /path/to/my_script.sh on the docker host, not necessarily in host's $PWD
# dangling "
c=container!
echo $HOST_HOSTNAME
echo $HOSTNAME
echo $@
echo $1
# a comment
echo $2
echo $3
eval echo \$$3
# another comment
```
Invoke with:
``` shell
EMBARK_DOCKER_RUN=/path/to/my_script.sh
a=host!
run_embark -e HOST_HOSTNAME=$HOSTNAME -- $a b c
```

Node.js variant:
``` javascript
#!/usr/bin/env node
// this script is located at /path/to/my_node_script.js on the docker host, not necessarily in host's $PWD
const o = {c: 'container!'};
console.log(process.env.HOST_HOSTNAME);
console.log(process.env.HOSTNAME);
console.log(JSON.stringify(process.argv));
console.log(process.argv[2]);
console.log(process.argv[3]);
console.log(process.argv[4]);
console.log(o[process.argv[4]]);
```
Invoke the same way:
``` shell
EMBARK_DOCKER_RUN=/path/to/my_node_script.js
a=host!
run_embark -e HOST_HOSTNAME=$HOSTNAME -- $a b c
```

#### `docker exec`

When executing compound commands via `docer exec` in a running embark
container, `su-exec` and `bash -[i]c` can be used together.

``` shell
docker exec -it $container_id su-exec embark \
       bash -ic 'exec bash << "SCRIPT"

simple_nodeenv 10.7.0 my_node || nac my_node
npm i -g http-server
exec http-server -p 8000

SCRIPT
'
```

To go non-interactive, manually source the embark user's `.bash_env`.

``` shell
docker exec -it $container_id su-exec embark \
       bash -c 'exec bash << "SCRIPT"

. ~/.bash_env
simple_nodeenv 10.7.0 my_node || nac my_node
npm i -g http-server
exec http-server -p 8000

SCRIPT
'
```

## Container development

### Updating versions

* Open `Dockerfile`
* On the `ARG` directives, update necessary versions.

### Building

Building requires Docker to be installed on your local machine.

#### Scripted

If you have Ruby installed in your system, run:

```
$ ruby script/build
```

To release, add `--release` as a parameter of the build script.

#### Manually

Building and releasing manually isn't too hard either, but there are a couple
steps.

##### Tags

To facilitate the images being found, we tag them with the following rules (as
an example, the `3.1.5` version will be used.)

- Tag with `statusim/embark:latest` if `3.1.5` is the latest version.
- Tag with `statusim/embark:3.1.5`
- Tag with `statusim/embark:3.1` if `3.1.5` is the highest patch level on `3.1`
- Tag with `statusim/embark:3` if `3.1.5` is the highest minor and patch level
  on `3`

##### Generating the image

To generate the image, run:

```
docker build . -t statusim/embark:<version> [...tags]
```

### Releasing

Releasing requires that you're authenticated to Docker Hub. To do so, run:

```
$ docker login
```

#### Scripted

If you have Ruby installed in your system, run:

```
$ ruby script/build --release
```

#### Manual

Pushing the tags manually implies that the image has been previously built. To
push your local images, run:

```
docker push statusim/embark:version
```
