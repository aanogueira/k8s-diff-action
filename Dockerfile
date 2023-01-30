FROM alpine:3.17.1

COPY entrypoint.sh /entrypoint.sh

# https://github.com/kubernetes-sigs/kustomize/releases
ARG KUSTOMIZE_VERSION=4.5.7

# https://github.com/instrumenta/kubeval/releases
ARG KUSTOMIZE_VERSION=v0.16.1

# split layers into distinct components
RUN apk add --no-cache --upgrade ca-certificates curl tar perl yq \
  && apk add kubectl helm --no-cache --repository http://dl-3.alpinelinux.org/alpine/edge/testing/ --allow-untrusted

# Install Kustomize
RUN mkdir /tmp/kustomize \
  && curl -s -L -o /tmp/kustomize/kustomize.tar.gz \
  https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv${KUSTOMIZE_VERSION}/kustomize_v${KUSTOMIZE_VERSION}_linux_amd64.tar.gz \
  && tar -xzf /tmp/kustomize/kustomize.tar.gz -C /tmp/kustomize \
  && mv /tmp/kustomize/kustomize /usr/local/bin \
  && chmod +x /usr/local/bin/kustomize \
  && rm -rf /tmp/kustomize

# Install Kubeval
RUN mkdir /tmp/kubeval \
&& curl -s -L -o /tmp/kubeval/kubeval.tar.gz \
  https://github.com/instrumenta/kubeval/releases/download/${KUBEVAL_VERSION}/kubeval-linux-amd64.tar.gz \
  && tar -xzf /tmp/kubeval/kubeval.tar.gz -C /tmp/kubeval \
  && mv /tmp/kubeval/kubeval /usr/local/bin \
  && chmod +x /usr/local/bin/kubeval \
  && rm -rf /tmp/kubeval

ENTRYPOINT ["/entrypoint.sh"]
