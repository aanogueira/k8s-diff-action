FROM alpine:3.17.1

# https://github.com/kubernetes-sigs/kustomize/releases
ARG KUSTOMIZE_VERSION=4.5.7

# https://github.com/instrumenta/kubeval/releases
ARG KUBEVAL_VERSION=0.16.1

WORKDIR /app

COPY entrypoint.sh entrypoint.sh
COPY requirements.txt requirements.txt
COPY main.py main.py

ENV PYTHONUNBUFFERED=1

ENV USER=docker
ENV UID=12345
ENV GID=23456

RUN addgroup --gid "$GID" "$USER" && \
    adduser \
    --disabled-password \
    --gecos "" \
    --home "$(pwd)" \
    --ingroup "$USER" \
    --no-create-home \
    --uid "$UID" \
    "$USER"

# split layers into distinct components
RUN apk add --no-cache --upgrade ca-certificates curl tar perl yq \
  && apk add kubectl helm --no-cache --repository http://dl-3.alpinelinux.org/alpine/edge/testing/ --allow-untrusted

# Install Kustomize
RUN mkdir /tmp/kustomize \
  && curl -s -L -o /tmp/kustomize/kustomize.tar.gz \
  "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv${KUSTOMIZE_VERSION}/kustomize_v${KUSTOMIZE_VERSION}_linux_amd64.tar.gz" \
  && tar -xzf /tmp/kustomize/kustomize.tar.gz -C /tmp/kustomize \
  && mv /tmp/kustomize/kustomize /usr/local/bin \
  && chmod +x /usr/local/bin/kustomize \
  && rm -rf /tmp/kustomize

# Install Kubeval
RUN mkdir /tmp/kubeval \
&& curl -s -L -o /tmp/kubeval/kubeval.tar.gz \
  "https://github.com/instrumenta/kubeval/releases/download/v${KUBEVAL_VERSION}/kubeval-linux-amd64.tar.gz" \
  && tar -xzf /tmp/kubeval/kubeval.tar.gz -C /tmp/kubeval \
  && mv /tmp/kubeval/kubeval /usr/local/bin \
  && chmod +x /usr/local/bin/kubeval \
  && rm -rf /tmp/kubeval

# Install python an pip
RUN apk add --update --no-cache python3 && ln -sf python3 /usr/bin/python
RUN python3 -m ensurepip
RUN pip3 install --no-cache --upgrade pip setuptools

# Install python dependencies
RUN pip3 install -r requirements.txt

ENTRYPOINT ["/app/entrypoint.sh"]
