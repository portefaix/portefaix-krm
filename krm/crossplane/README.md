# KRM / Crossplane

* Create Kind cluster :

```shell
❯ make kind-create ENV=crossplane
```

* Install Crossplane:

```shell
❯ make crossplane-controlplane ENV=crossplane
```

## Cloud provider credentials

* Choose the cloud provider (`aws`, `gcp` or `azure`)

```shell
❯ export CLOUD=xxx
```

* Setup credentials

```shell
❯ make crossplane-credentials
```

## Crossplane Cloud Provider configuration

* Install Crossplane provider:

```shell
❯ make crossplane-provider ACTION=apply
```

For Scaleway, execute also:

```shell
❯ kustomize build krm/crossplane/scaleway/crds | kubectl apply --server-side=true -f -
```

* Setup Crossplane configuration:

```shell
❯ make crossplane-config ACTION=apply
```

* Deploy infrastructure:

```shell
❯ make crossplane-infra ACTION=apply
```

* Delete infrastructure:

```shell
❯ make crossplane-infra ACTION=delete
```
