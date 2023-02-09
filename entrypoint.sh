#!/bin/sh -l

echo "INFO - Downloading Flux OpenAPI schemas"
mkdir -p /tmp/flux-crd-schemas/master-standalone-strict
curl -sL https://github.com/fluxcd/flux2/releases/latest/download/crd-schemas.tar.gz | tar zxf - -C /tmp/flux-crd-schemas/master-standalone-strict
find . -type f -name '*.yaml' -print0 | while IFS= read -r -d $'\0' file;
  do
    echo "INFO - Validating $file"
    yq -e 'true' "$file" > /dev/null
done

echo "INFO - Validating clusters"
find ./clusters -maxdepth 2 -type f -name '*.yaml' -print0 | while IFS= read -r -d $'\0' file;
  do
    kubeval ${file} --strict --ignore-missing-schemas --additional-schema-locations=file:///tmp/flux-crd-schemas
    if [[ ${PIPESTATUS[0]} != 0 ]]; then
      exit 1
    fi
done

kustomize_flags="--load-restrictor=LoadRestrictionsNone --reorder=legacy"
kustomize_config="kustomization.yaml"

echo "INFO - Validating kustomize overlays"
find . -type f -name $kustomize_config -print0 | while IFS= read -r -d $'\0' file;
  do
    echo "INFO - Validating kustomization ${file/%$kustomize_config}"
    kustomize build "${file/%$kustomize_config}" $kustomize_flags | \
      kubeval --ignore-missing-schemas --strict --additional-schema-locations=file:///tmp/flux-crd-schemas
    if [[ ${PIPESTATUS[0]} != 0 ]]; then
      exit 1
    fi
done

if [ "$5" -eq '' ]; then
  if [ "$2" -eq '' ]; then
    echo "Missing 'server-url' parameter!"
    exit 1
  fi

  if [ "$3" -eq '' ]; then
    echo "Missing 'server-ca' parameter!"
    exit 1
  fi

  if [ "$4" -eq '' ]; then
    echo "Missing 'sa-token' parameter!"
    exit 1
  fi

  cat /work/ca.crt > ca.crt
  echo "$3" | base64 -d > ca.crt
  context="local"
  kubectl config set-cluster "$context" --server "$2" --certificate-authority ca.crt --embed-certs=true
  kubectl config set-credentials actions-runner --token "$4"
  kubectl config set-context "$context" --cluster "$context" --user actions-runner --namespace default
  kubectl config use-context "$context"
else
  mkdir -p ~/.kube
  echo "$5" | base64 -d > ~/.kube/config
  context=$(echo "$1" | cut -d'/' -f2)
  kubectl config use-context "$context"
fi

echo "INFO - Running resources diff"
echo "diff<<EOF" >> "$GITHUB_OUTPUT"
echo "$(for var in $(kubectl --context $context kustomize $1 | grep -o '${[^}]*}' | awk -F"[{}]" '{print$2}'); do \
  unset $var && export $var=$(\
    kubectl --context $context get cm cluster-values -n flux-system -o yaml | \
    grep "^  $var" | \
    awk '{sub(/:/," ");$1=$1;print $2}' | \
    tr -d " " | tr -d '"'); \
  done; \
  echo "--- HELM RELEASE DIFF---"; \
  kubectl --context $context kustomize $1 | perl -pe 's{(?|\$\{([_a-zA-Z]\w*)\}|\$([_a-zA-Z]\w*))}{$ENV{$1}//$&}ge' | \
  kubectl --context $context diff -f -; \
  echo "--- HELM RESOURCES DIFF---"; \
  for file in $(/bin/ls $kustomize_path | grep -v kustomization.yaml); do \
    python3 /app/main.py $PWD/$kustomize_path/$file $PWD/sources; \
  done \
)" >> "$GITHUB_OUTPUT"
echo "EOF" >> "$GITHUB_OUTPUT"
