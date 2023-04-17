# KRM / ACK

* Create Kind cluster :

```shell
> make kind-create ENV=aws
```

## Cloud provider credentials

```shell
> make ack-aws-credentials AWS_ACCESS_KEY=xxxxxx AWS_SECRET_KEY=xxxxxxxxx
```

## ACK Control Plane

* Install ACK controllers:

```shell
> make kcc-install
```

* Check controller:

```shell
> kubectl -n ack-system get pods -l "app.kubernetes.io/instance=ack-ec2-controller"
> kubectl -n ack-system get pods -l "app.kubernetes.io/instance=ack-ecr-controller"
> kubectl -n ack-system get pods -l "app.kubernetes.io/instance=ack-eks-controller"
> kubectl -n ack-system get pods -l "app.kubernetes.io/instance=ack-iam-controller"
> kubectl -n ack-system get pods -l "app.kubernetes.io/instance=ack-s3-controller"
```

* Clean cluster:

```shell
> make kcc-uninstall
```
