#!/bin/sh -l

echo $3 | base64 -d > server.ca
kubectl config set-cluster local --server $2 --certificate-authority server.ca --embed-certs=true
kubectl config set-credentials actions-runner --token $4
kubectl config set-context local --cluster local --user actions-runner --namespace default
kubectl config use-context local

echo "diff<<EOF" >> $GITHUB_OUTPUT
echo "$(for var in $(kubectl kustomize --context local $1 | grep -o '{[^}]*}' | awk -F"[{}]" '{print$2}'); do \
    unset $var && export $var=$(\
      kubectl get --context local cm cluster-values -n flux-system -o yaml | \
      grep $var | \
      awk '{sub(/:/," ");$1=$1;print $2}' | \
      tr -d " "); \
    done; \
  kubectl kustomize --context local $1 | envsubst | \
  kubectl diff --context local -f -\
)" >> $GITHUB_OUTPUT
echo "EOF" >> $GITHUB_OUTPUT
