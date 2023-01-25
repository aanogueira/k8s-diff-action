# Kubernetes Kustomize Resources Diff

Used to output the diff of the resources applied on a cluster.

## Inputs

## `folder`

**Required** The name of the folder where the action will run. Default `"."`.

## Outputs

## `diff`

The resource diffs found.

## Example usage

uses: actions/k8s-Kustomize-diff-action@v1
with:
  folder: 'example/folder'
