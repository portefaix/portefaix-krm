# Portefaix KRM

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

## Description

Build cloud platform using [Kubernetes Resources Model](https://github.com/kubernetes/community/blob/master/contributors/design-proposals/architecture/resource-management.md)

### Core

* Create Kind cluster :

```shell
> make kind-create ENV=local
```

* Install Crossplane:

```shell
> make crossplane-controlplane ACTION=apply
```

### AWS

* Cloud provider configuration:

```shell
> make crossplane-aws-credentials AWS_ACCESS_KEY=xxxxxx AWS_SECRET_KEY=xxxxxxxxx
```

* Install Crossplane provider:

```shell
> make crossplane-provider CLOUD=aws ACTION=apply
```

* Setup Crossplane configuration:

```shell
❯ make crossplane-config CLOUD=aws ACTION=apply
```

* Deploy infrastructure:

```shell
❯ make crossplane-infra CLOUD=aws ACTION=apply
```

### GCP

* Cloud provider configuration:

```shell
> make crossplane-gcp-credentials GCP_PROJECT_ID=myproject-prod GCP_SERVICE_ACCOUNT_NAME=kubernetes-krm
```

* Install Crossplane provider:

```shell
> make crossplane-provider CLOUD=gcp ACTION=apply
```

* Setup Crossplane configuration:

```shell
❯ make crossplane-config CLOUD=gcp ACTION=apply
```

* Deploy infrastructure:

```shell
❯ make crossplane-infra CLOUD=aws ACTION=apply
```

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md)

## License

[Apache 2.0 License](./LICENSE)