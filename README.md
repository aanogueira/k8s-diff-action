# Kubernetes Kustomize Resources Diff

Used to output the diff of the resources applied on a cluster.

## Inputs

`folder`

**Required** The name of the folder where the action will run. Default `"."`.

`server-url`

**Required** The URL of the Kubernetes server. Default `""`.

`server-ca`

**Required** The CA of the Kubernetes server. Default `""`.

`sa-token`

**Required** The token used to connect to the Kubernetes server. Default `""`.

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
```
