# Kubernetes Kustomize Resources Diff

Used to output the diff of the resources applied on a cluster.

## Inputs

`folder`

**Required** The name of the folder where the action will run. Default `"."`.

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
  folder: example/folder
  server-url: https://example.local
  server-ca: <ca_b64_encoded>
  sa-token: <token_b64_decoded>
  kubeconfig: <file_b64_encoded>
```
