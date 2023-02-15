#!/bin/sh
docker buildx build --local --platform linux/amd64,linux/arm64 -t dominikborkowski/alpine-docker-aws-cli .
