# Embark for Docker

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

Building and releasing manually isn't too hard either, but there are a couple steps.

#### Tags

To facilitate the images being found, we tag them with the following rules (as an example, the `3.1.5` version will be used.)

- Tag with `statusim/embark:latest` if `3.1.5` is the latest version.
- Tag with `statusim/embark:3.1.5`
- Tag with `statusim/embark:3.1` if `3.1.5` is the highest patch level on `3.1`
- Tag with `statusim/embark:3` if `3.1.5` is the highest minor and patch level on `3`

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

Pushing the tags manually implies that the image has been previously built. To push your local images, run:

```
docker push statusim/embark:version
```
