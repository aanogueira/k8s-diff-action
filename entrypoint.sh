#!/bin/sh -l

# if [ $2 -eq '' ]; then
#   INPUT_SERVER_URL=$(echo $SERVER_URL)
# else
#   INPUT_SERVER_URL=$2
# fi

# if [ $3 -eq '']; then
#   cat /work/ca.crt > ca.crt
# else
#   echo $3 | base64 -d > ca.crt
# fi

# if [ $4 -eq '']; then
#   INPUT_SA_TOKEN=$(cat /work/token)
# else
#   INPUT_SA_TOKEN=$4
# fi

# kubectl config set-cluster local --server $INPUT_SERVER_URL --certificate-authority ca.crt --embed-certs=true
# kubectl config set-credentials actions-runner --token $INPUT_SA_TOKEN
# kubectl config set-context local --cluster local --user actions-runner --namespace default
# kubectl config use-context local

# echo "diff<<EOF" >> $GITHUB_OUTPUT
# echo "$(for var in $(kubectl kustomize --context local $1 | grep -o '{[^}]*}' | awk -F"[{}]" '{print$2}'); do \
#     unset $var && export $var=$(\
#       kubectl get --context local cm cluster-values -n flux-system -o yaml | \
#       grep $var | \
#       awk '{sub(/:/," ");$1=$1;print $2}' | \
#       tr -d " "); \
#     done; \
#   kubectl kustomize --context local $1 | envsubst | \
#   kubectl diff --context local -f -\
# )" >> $GITHUB_OUTPUT
# echo "EOF" >> $GITHUB_OUTPUT

echo "diff<<EOF" >> $GITHUB_OUTPUT
echo "$(for var in $(kubectl kustomize $1 | grep -o '{[^}]*}' | awk -F"[{}]" '{print$2}'); do \
    unset $var && export $var=$(\
      kubectl get cm cluster-values -n flux-system -o yaml | \
      grep $var | \
      awk '{sub(/:/," ");$1=$1;print $2}' | \
      tr -d " "); \
    done; \
  kubectl kustomize $1 | envsubst | \
  kubectl diff -f -\
)" >> $GITHUB_OUTPUT
echo "EOF" >> $GITHUB_OUTPUT
