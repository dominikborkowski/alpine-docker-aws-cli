#!/bin/sh
docker buildx build --load -t dominikborkowski/alpine-docker-aws-cli --builder=container .
