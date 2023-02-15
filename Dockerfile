ARG ALPINE_VERSION=3.17
ARG DOCKER_VERSION=20
# ARG DOCKER_VERSION=23

# Build AWS CLI v2
FROM python:3.10-alpine${ALPINE_VERSION} as aws_cli_builder
ARG AWS_CLI_VERSION=2.9.23
RUN apk add --no-cache git unzip groff build-base libffi-dev cmake
RUN git clone --single-branch --depth 1 -b ${AWS_CLI_VERSION} https://github.com/aws/aws-cli.git
WORKDIR aws-cli
RUN python -m venv venv
RUN . venv/bin/activate
RUN scripts/installers/make-exe
RUN unzip -q dist/awscli-exe.zip
RUN aws/install --bin-dir /aws-cli-bin
RUN /aws-cli-bin/aws --version

# Reduce image size: remove autocomplete and examples
RUN rm -rf \
    /usr/local/aws-cli/v2/current/dist/aws_completer \
    /usr/local/aws-cli/v2/current/dist/awscli/data/ac.index \
    /usr/local/aws-cli/v2/current/dist/awscli/examples
RUN find /usr/local/aws-cli/v2/current/dist/awscli/data -name completions-1*.json -delete
RUN find /usr/local/aws-cli/v2/current/dist/awscli/botocore/data -name examples-1.json -delete

# Build the final image using docker image as the starting point, then copy in aws-cli
FROM docker:${DOCKER_VERSION}
LABEL maintainer "Dominik L. Borkowski"
COPY --from=aws_cli_builder /usr/local/aws-cli/ /usr/local/aws-cli/
COPY --from=aws_cli_builder /aws-cli-bin/ /usr/local/bin/

# Install few essential tools and AWS SAM CLI, then clean up
RUN apk --no-cache --upgrade --virtual=build_environment add \
    gcc python3-dev py3-pip musl-dev libffi-dev openssl-dev && \
    apk --no-cache --upgrade --virtual=random_tools add \
    bash curl git python3 rsync && \
    pip3 --no-cache-dir install --upgrade aws-sam-cli && \
    apk --no-cache del build_environment && \
    rm -rf /var/cache/apk/* && \
    find / -type f -name "*.py[co]" -delete
