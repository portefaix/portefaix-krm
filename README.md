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

### Cloud provider credentials

* AWS

```shell
> make crossplane-aws-credentials AWS_ACCESS_KEY=xxxxxx AWS_SECRET_KEY=xxxxxxxxx
```

* GCP

```shell
> make crossplane-gcp-credentials GCP_PROJECT_ID=myproject-prod GCP_SERVICE_ACCOUNT_NAME=kubernetes-krm
```

* Azure

```shell
> make crossplane-azure-credentials AZURE_SUBSCRIPTION_ID=xxxxxxx AZURE_PROJECT_NAME=xxxxxx
```

### Crossplane Cloud Provider configuration

* Choose the cloud provider (`aws`, `gcp` or `azure`)

```shell
> export CROSSPLANE_CLOUD_PROVIDER=xxx
```

* Install Crossplane provider:

```shell
> make crossplane-provider CLOUD=${CROSSPLANE_CLOUD_PROVIDER} ACTION=apply
```

* Setup Crossplane configuration:

```shell
❯ make crossplane-config CLOUD=${CROSSPLANE_CLOUD_PROVIDER} ACTION=apply
```

* Deploy infrastructure:

```shell
❯ make crossplane-infra CLOUD=${CROSSPLANE_CLOUD_PROVIDER} ACTION=apply
```

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md)

## License

[Apache 2.0 License](./LICENSE)