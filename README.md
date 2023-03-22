# Kubernetes Kustomize Resources Diff

Used to output the diff of the resources applied on a cluster.

## Inputs

`kustomize_folder`

**Required** The name of the folder where `kustomization.yaml` resides. Default `"."`.

`local_cluster`

**Optional** Wether the action will have local access to the kubernetes cluster. Default `false`.

`sources_folder`

**Optional** The name of the folder where the helm sources resides. Default `"sources"`.

`kubeconfig`

**Optional** Kubernetes config file used connect to the server. Default `""`.

`server-url`

**Optional** The URL of the Kubernetes server. Default `""`.

`server-ca`

**Optional** The CA of the Kubernetes server. Default `""`.

`sa-token`

**Optional** The token used to connect to the Kubernetes server. Default `""`.

## Outputs

`diff`

The resource diffs found.

## Example usage

```yaml
uses: actions/k8s-Kustomize-diff-action@v1
with:
  kustomize_folder: example/folder
  local_cluster: false
  sources_folder: sources
  server-url: https://example.local
  server-ca: <ca_b64_encoded>
  sa-token: <token_b64_decoded>
  kubeconfig: <file_b64_encoded>
```
