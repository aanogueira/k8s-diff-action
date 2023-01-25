#!/bin/sh -l

echo "{diff}={$(\
  for var in $(kubectl kustomize $1 | grep '{' |awk -F"[{}]" '{print$2}'); do \
    unset $var && export $var=$(\
      kubectl get cm cluster-values -n flux-system -o yaml | \
      grep $var | \
      awk '{sub(/:/," ");$1=$1;print $2}' | \
      tr -d " "); \
    done; \
  kubectl kustomize $1 | envsubst | \
  kubectl diff -f -\
)}" >> $GITHUB_OUTPUT
