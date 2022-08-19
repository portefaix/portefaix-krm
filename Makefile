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

include hack/commons.mk
-include hack/kind.$(ENV).mk

KIND_VERSION := $(shell kind --version 2>/dev/null)

HELM_CROSSPLANE_VERSION=1.4.1

KIND_VERSION = v0.14.0

CROSSPLANE_NAMESPACE = crossplane-system

ACK_SYSTEM_NAMESPACE = ack-system
AWS_REGION = us-west-2
ACK_EC2_VERSION = v0.0.17
ACK_ECR_VERSION = v0.1.5
ACK_EKS_VERSION = v0.1.5
ACK_IAM_VERSION = v0.0.19
ACK_S3_VERSION = v0.1.4

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

.PHONY: kind-install
kind-install: ## Install Kind
ifdef KIND_VERSION
	@echo "Found version $(KIND_VERSION)"
else
	@curl -Lo ./kind https://kind.sigs.k8s.io/dl/$(KIND_VERSION)kind-linux-amd64
	@chmod +x ./kind
	@mv ./kind /bin/kind
endif

.PHONY: kind-create
kind-create: guard-ENV ## Creates a local Kubernetes cluster (ENV=xxx)
	@echo -e "$(OK_COLOR)[$(APP)] Create Kubernetes cluster ${SERVICE}$(NO_COLOR)"
	@kind create cluster --name=$(CLUSTER) --config=hack/kind-config.yaml --wait 180s

.PHONY: kind-delete
kind-delete: guard-ENV ## Delete a local Kubernetes cluster (ENV=xxx)
	@echo -e "$(OK_COLOR)[$(APP)] Delete Kubernetes cluster ${SERVICE}$(NO_COLOR)"
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
	@helm install crossplane --create-namespace --namespace $(CROSSPLANE_NAMESPACE) crossplane-stable/crossplane --version $(HELM_CROSSPLANE_VERSION)

.PHONY: crossplane-provider
crossplane-provider: guard-CLOUD guard-ACTION ## Setup the Crossplane provider (CLOUD=xxx ACTION=xxx)
	@kustomize build krm/$(CLOUD)/provider | kubectl $(ACTION) -f -

.PHONY: crossplane-config
crossplane-config: guard-CLOUD guard-ACTION ## The Crossplane configuration (CLOUD=xxx ACTION=xxx)
	@kustomize build krm/$(CLOUD)/config | kubectl $(ACTION) -f -

.PHONY: crossplane-infra
crossplane-infra: guard-CLOUD guard-ACTION ## Manage the components (CLOUD=xxx ACTION=xxx)
	@kustomize build krm/$(CLOUD)/infra | kubectl $(ACTION) -f -

.PHONY: crossplane-gcp-credentials
crossplane-gcp-credentials: guard-GCP_PROJECT_ID guard-GCP_SERVICE_ACCOUNT_NAME ## Generate credentials for GCP (GCP_PROJECT_ID=xxx GCP_SERVICE_ACCOUNT_NAME=xxx GCP_SERVICE_ACCOUNT_KEYFILE=xxx)
	@./hack/scripts/gcp.sh $(GCP_PROJECT_ID) $(GCP_SERVICE_ACCOUNT_NAME)

.PHONY: crossplane-aws-credentials
crossplane-aws-credentials: guard-AWS_ACCESS_KEY_ID guard-AWS_SECRET_ACCESS_KEY ## Generate credentials for AWS (AWS_ACCESS_KEY=xxx AWS_SECRET_ACCESS_KEY=xxx)
	@./hack/scripts/aws.sh $(AWS_ACCESS_KEY_ID) $(AWS_SECRET_ACCESS_KEY) crossplane-aws-credentials crossplane-system

.PHONY: crossplane-azure-credentials
crossplane-azure-credentials: guard-AZURE_SUBSCRIPTION_ID guard-AZURE_PROJECT_NAME ## Generate credentials for Azure
	@./hack/scripts/azure.sh $(AZURE_SUBSCRIPTION_ID) $(AZURE_PROJECT_NAME)


# ====================================
# ACK
# ====================================

##@ ACK

.PHONY: ack-aws
ack-aws: ## Authentication on the ECR public Helm registry
	aws ecr-public get-login-password --region us-east-1 | helm registry login --username AWS --password-stdin public.ecr.aws

.PHONY: ack-aws-credentials
ack-aws-credentials: guard-AWS_ACCESS_KEY_ID guard-AWS_SECRET_ACCESS_KEY ## Generate credentials for AWS (AWS_ACCESS_KEY=xxx AWS_SECRET_ACCESS_KEY=xxx)
	@./hack/scripts/aws.sh $(AWS_ACCESS_KEY_ID) $(AWS_SECRET_ACCESS_KEY) ack-aws-credentials ack-system

.PHONY: ack-install
ack-install: ## Install the ACK controllers
	helm upgrade --install --create-namespace --namespace $(ACK_SYSTEM_NAMESPACE) ack-ec2-controller \
		oci://public.ecr.aws/aws-controllers-k8s/ec2-chart --version=$(ACK_ECR_VERSION) \
		-f krm/ack/ec2-values.yaml
	helm upgrade --install --create-namespace --namespace $(ACK_SYSTEM_NAMESPACE) ack-ecr-controller \
		oci://public.ecr.aws/aws-controllers-k8s/ecr-chart --version=$(ACK_ECR_VERSION) \
		-f krm/ack/ecr-values.yaml
	helm upgrade --install --create-namespace --namespace $(ACK_SYSTEM_NAMESPACE) ack-eks-controller \
		oci://public.ecr.aws/aws-controllers-k8s/eks-chart --version=$(ACK_EKS_VERSION) \
		-f krm/ack/eks-values.yaml
	helm install --create-namespace --namespace $(ACK_SYSTEM_NAMESPACE) ack-iam-controller \
		oci://public.ecr.aws/aws-controllers-k8s/iam-chart --version=$(ACK_IAM_VERSION) \
		-f krm/ack/iam-values.yaml
	helm install --create-namespace --namespace $(ACK_SYSTEM_NAMESPACE) ack-s3-controller \
		oci://public.ecr.aws/aws-controllers-k8s/s3-chart --version=$(ACK_S3_VERSION) \
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