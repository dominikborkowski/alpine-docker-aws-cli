#!/bin/sh
docker buildx build --push -t dominikborkowski/alpine-docker-aws-cli --builder=container .
