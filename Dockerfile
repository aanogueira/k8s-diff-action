FROM alpine:3.17.1

# https://github.com/kubernetes-sigs/kustomize/releases
ARG KUSTOMIZE_VERSION=4.5.7

ENV KUBECTL_EXTERNAL_DIFF="colordiff -N -u"

# split layers into distinct components
RUN apk add --no-cache --upgrade ca-certificates curl tar colordiff \
  && apk add kubectl helm envsubst --no-cache --repository http://dl-3.alpinelinux.org/alpine/edge/testing/ --allow-untrusted

# Install Kustomize
RUN mkdir /tmp/kustomize \
  && curl -s -L -o /tmp/kustomize/kustomize.tar.gz \
  https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv${KUSTOMIZE_VERSION}/kustomize_v${KUSTOMIZE_VERSION}_linux_amd64.tar.gz \
  && tar -xzf /tmp/kustomize/kustomize.tar.gz -C /tmp/kustomize \
  && mv /tmp/kustomize/kustomize /usr/local/bin \
  && chmod +x /usr/local/bin/kustomize \
  && rm -rf /tmp/kustomize

ENTRYPOINT ["/entrypoint.sh"]
