### KRM / ACK

* Create Kind cluster :

```shell
> make kind-create ENV=aws
```

* Install ACK:

```shell
> make ack-controlplane ENV=aws
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

* Install ACK controllers:

```shell
> make ack-controlplane
```

