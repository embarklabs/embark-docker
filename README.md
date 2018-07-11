# Embark for Docker

## Updating versions

* Open `Dockerfile`
* On the `ENV` directive, update necessary versions.

An exception to this is the NodeJS version, which needs to be updated in the `FROM` directive instead.

## Building

Building requires Docker to be installed on your local machine. To build, run:

```
$ script/build
```

## Releasing

Releasing requires that you're authenticated to Docker Hub. To do so, run:

```
$ docker login
```

After, or if you're already authenticated, run:

```
$ script/build --release
```
