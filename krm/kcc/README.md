# KRM / KCC

Resources: https://cloud.google.com/config-connector/docs/reference/overview

* Create Kind cluster :

```shell
> make kind-create ENV=gcp
```

## Cloud provider credentials

```shell
> make kcc-gcp-credentials
```

## KCC Control Plane

* Install KCC:

```shell
> make kcc-install
```

* Check controllers:

```shell

```

* Clean cluster:

```shell
> make kcc-uninstall
```
