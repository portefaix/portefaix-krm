# Copyright (C) Nicolas Lamirault <nicolas.lamirault@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# SPDX-License-Identifier: Apache-2.0

include hack/commons.mk
-include hack/kind.$(ENV).mk

KUBE_CONTEXT = $(KUBE_CONTEXT_$(ENV))
KUBE_CURRENT_CONTEXT = $(shell kubectl config current-context)
CLUSTER = $(CLUSTER_$(ENV))

# datasource=github-tags depName=crossplane/crossplane
CROSSPLANE_VERSION = v1.17.1
CROSSPLANE_NAMESPACE = crossplane-system

ACK_SYSTEM_NAMESPACE = ack-system
AWS_REGION = us-west-2
# datasource=github-tags depName=aws-controllers-k8s/ec2-controller
ACK_EC2_VERSION = v1.2.26
# datasource=github-tags depName=aws-controllers-k8s/ecr-controller
ACK_ECR_VERSION = v1.0.18
# datasource=github-tags depName=aws-controllers-k8s/eks-controller
ACK_EKS_VERSION = v1.4.6
# datasource=github-tags depName=aws-controllers-k8s/iam-controller
ACK_IAM_VERSION = v1.3.12
# datasource=github-tags depName=aws-controllers-k8s/s3-controller
ACK_S3_VERSION = v1.0.16

ASO_SYSTEM_NAMESPACE = aso-system
# datasource=github-tags depName=Azure/azure-service-operator
ASO_VERSION = v2.9.0

KCC_SYSTEM_NAMESPACE = cnrm-system
# datasource=github-tags depName=GoogleCloudPlatform/k8s-config-connector
ASO_VERSION = v1.123.1

# ====================================
# D E V E L O P M E N T
# ====================================

##@ Development

.PHONY: clean
clean: ## Cleanup
	@echo -e "$(OK_COLOR)[$(BANNER)] Cleanup$(NO_COLOR)"
	@find . -name "*.retry"|xargs rm -f
	@rm -fr vendor
	@rm -fr venv

.PHONY: check
check: check-kubectl check-kustomize check-helm ## Check requirements

.PHONY: validate
validate: ## Execute git-hooks
	@poetry run pre-commit run -a

.PHONY: kind-create
kind-create: guard-ENV ## Creates a local Kubernetes cluster (ENV=xxx)
	@echo -e "$(OK_COLOR)[$(APP)] Create Kubernetes cluster $(CLUSTER)$(NO_COLOR)"
	@kind create cluster --name=$(CLUSTER) --config=hack/kind-config.yaml --wait 180s

.PHONY: kind-delete
kind-delete: guard-ENV ## Delete a local Kubernetes cluster (ENV=xxx)
	@echo -e "$(OK_COLOR)[$(APP)] Delete Kubernetes cluster $(CLUSTER)$(NO_COLOR)"
	@kind delete cluster --name=$(CLUSTER)

kubernetes-check-context:
	@if [[ "$(KUBE_CONTEXT)" != "$(KUBE_CURRENT_CONTEXT)" ]] ; then \
		echo -e "$(ERROR_COLOR)[KO]$(NO_COLOR) Kubernetes context: $(KUBE_CONTEXT) vs $(KUBE_CURRENT_CONTEXT)"; \
		exit 1; \
	fi

.PHONY: kubernetes-switch
kubernetes-switch: guard-ENV ## Switch Kubernetes context (ENV=xxx)
	@kubectl config use-context $(KUBE_CONTEXT)

.PHONY: kubernetes-secret
kubernetes-secret: guard-NAMESPACE guard-NAME guard-FILE ## Generate a Kubernetes secret file (NAME=xxxx NAMESPACE=xxxx FILE=xxxx)
	@kubectl create secret generic $(NAME) -n $(NAMESPACE) --dry-run=client --from-file=$(FILE) -o yaml

.PHONY: kubernetes-credentials
kubernetes-credentials: guard-ENV guard-CLOUD ## Generate credentials (CLOUD=xxxx ENV=xxx)
	@kubectl config use-context $(KUBE_CONTEXT)

# ====================================
# C R O S S P L A N E
# ====================================

##@ Crossplane

.PHONY: crossplane-controlplane
crossplane-controlplane: ## Install Crossplane using Helm
	@helm repo add crossplane-stable https://charts.crossplane.io/stable
	@helm repo update
	@helm upgrade --install crossplane --create-namespace \
		--namespace $(CROSSPLANE_NAMESPACE) crossplane-stable/crossplane \
		--version v$(CROSSPLANE_VERSION)

.PHONY: crossplane-provider
crossplane-provider: guard-CLOUD guard-ACTION ## Setup the Crossplane provider (CLOUD=xxx ACTION=xxx)
	@kustomize build krm/crossplane/$(CLOUD)/provider | kubectl $(ACTION) -f -

.PHONY: crossplane-config
crossplane-config: guard-CLOUD guard-ACTION ## The Crossplane configuration (CLOUD=xxx ACTION=xxx)
	@kustomize build krm/crossplane/$(CLOUD)/config | kubectl $(ACTION) -f -

.PHONY: crossplane-infra
crossplane-infra: guard-CLOUD guard-ACTION ## Manage the components (CLOUD=xxx ACTION=xxx)
	@kustomize build krm/crossplane/$(CLOUD)/infra | kubectl $(ACTION) -f -

.PHONY: crossplane-credentials
crossplane-credentials: guard-CLOUD ## Generate credentials for a Cloud provider (CLOUD=xxx)
	@./hack/scripts/$(CLOUD).sh crossplane-$(CLOUD)-credentials crossplane-system


# ====================================
# ACK
# ====================================

##@ ACK

.PHONY: ack-aws
ack-aws: ## Authentication on the ECR public Helm registry
	aws ecr-public get-login-password --region us-east-1 | helm registry login --username AWS --password-stdin public.ecr.aws

.PHONY: ack-aws-credentials
ack-aws-credentials: guard-AWS_ACCESS_KEY_ID guard-AWS_SECRET_ACCESS_KEY ## Generate credentials for AWS (AWS_ACCESS_KEY=xxx AWS_SECRET_ACCESS_KEY=xxx)
	@./hack/scripts/aws.sh $(AWS_ACCESS_KEY_ID) $(AWS_SECRET_ACCESS_KEY) ack-aws-credentials $(ACK_SYSTEM_NAMESPACE)

.PHONY: ack-install
ack-install: ## Install the ACK controllers
	helm upgrade --install --create-namespace --namespace $(ACK_SYSTEM_NAMESPACE) ack-ec2-controller \
		oci://public.ecr.aws/aws-controllers-k8s/ec2-chart --version=v$(ACK_EC2_VERSION) \
		-f krm/ack/ec2-values.yaml
	helm upgrade --install --create-namespace --namespace $(ACK_SYSTEM_NAMESPACE) ack-ecr-controller \
		oci://public.ecr.aws/aws-controllers-k8s/ecr-chart --version=v$(ACK_ECR_VERSION) \
		-f krm/ack/ecr-values.yaml
	helm upgrade --install --create-namespace --namespace $(ACK_SYSTEM_NAMESPACE) ack-eks-controller \
		oci://public.ecr.aws/aws-controllers-k8s/eks-chart --version=v$(ACK_EKS_VERSION) \
		-f krm/ack/eks-values.yaml
	helm upgrade --install --create-namespace --namespace $(ACK_SYSTEM_NAMESPACE) ack-iam-controller \
		oci://public.ecr.aws/aws-controllers-k8s/iam-chart --version=v$(ACK_IAM_VERSION) \
		-f krm/ack/iam-values.yaml
	helm upgrade --install --create-namespace --namespace $(ACK_SYSTEM_NAMESPACE) ack-s3-controller \
		oci://public.ecr.aws/aws-controllers-k8s/s3-chart --version=v$(ACK_S3_VERSION) \
		-f krm/ack/s3-values.yaml

.PHONY: ack-infra
ack-infra: guard-ACTION ## Manage the components (ACTION=xxx, apply or delete)
	@kustomize build krm/ack/infra | kubectl $(ACTION) -f -

.PHONY: ack-uninstall
ack-uninstall: ## Uninstall the ACK controllers
	helm uninstall -n $(ACK_SYSTEM_NAMESPACE) ack-ec2-controller
	helm uninstall -n $(ACK_SYSTEM_NAMESPACE) ack-ecr-controller
	helm uninstall -n $(ACK_SYSTEM_NAMESPACE) ack-eks-controller
	helm uninstall -n $(ACK_SYSTEM_NAMESPACE) ack-iam-controller
	helm uninstall -n $(ACK_SYSTEM_NAMESPACE) ack-s3-controller
	kubectl delete namespace $(ACK_SYSTEM_NAMESPACE)


# ====================================
# ASO
# ====================================

##@ ASO

.PHONY: aso-azure-credentials
aso-azure-credentials: guard-AZURE_TENANT_ID guard-AZURE_SUBSCRIPTION_ID ## Generate credentials for AWS (AZURE_TENANT_ID=xxx AZURE_SUBSCRIPTION_ID=xxx)
	@./hack/scripts/aso.sh aso-controller-settings $(ASO_SYSTEM_NAMESPACE)

.PHONY: aso-dependencies
aso-dependencies: ## Install dependencies
	@helm repo add cert-manager https://charts.jetstack.io
	@helm repo update
	@kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.9.1/cert-manager.crds.yaml \
		&& sleep 5
	@helm upgrade --install --create-namespace --namespace=cert-manager \
		cert-manager cert-manager/cert-manager --version 1.9.1

.PHONY: aso-install
aso-install: ## Install the ASO controlplane
	@helm repo add aso2 https://raw.githubusercontent.com/Azure/azure-service-operator/main/v2/charts
	@helm repo update
	@helm upgrade --install --devel --create-namespace --namespace=$(ASO_SYSTEM_NAMESPACE) azure-service-operator \
		aso2/azure-service-operator \
		--version=v$(ASO_VERSION) \
		-f krm/aso/values.yaml

.PHONY: aso-infra
aso-infra: guard-ACTION ## Manage the components (ACTION=xxx, apply or delete)
	@kustomize build krm/aso/infra | kubectl $(ACTION) -f -

.PHONY: aso-uninstall
aso-uninstall: ## Uninstall the ACK controllers
	@helm uninstall -n $(ASO_SYSTEM_NAMESPACE) azure-service-operator
	@kubectl delete namespace $(ASO_SYSTEM_NAMESPACE)
	@helm uninstall -n cert-manager cert-manager
	@kubectl delete namespace cert-manager


# ====================================
# KCC
# ====================================

##@ KCC

kcc-install: # Install the KCC controlplane
	helm upgrade --install --devel --create-namespace --namespace=$(KCC_SYSTEM_NAMESPACE) kubernetes-config-connector \
		aso2/azure-service-operator \
		--version=v$(KCC_VERSION) \
		-f krm/kcc/values.yaml

.PHONY: kcc-infra
kcc-infra: guard-ACTION ## Manage the components (ACTION=xxx, apply or delete)
	@kustomize build krm/kcc/infra | kubectl $(ACTION) -f -

.PHONY: kcc-uninstall
kcc-uninstall: ## Uninstall KCC controlplane
	@helm uninstall -n $(KCC_SYSTEM_NAMESPACE) kubernetes-config-connector
	@kubectl delete namespace $(KCC_SYSTEM_NAMESPACE)
