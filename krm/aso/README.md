# KRM / Azure Service Operator

* Create Kind cluster :

```shell
> make kind-create ENV=azure
```

## Controlplane

```shell
> make aso-dependencies
```

```shell
> make aso-install
```

```shell
> make aso-azure-credentials
```

* Check controllers:

```shell
```

## Clean

```shell
> make aso-uninstall
```
