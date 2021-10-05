# Copyright (C) 2021 Nicolas Lamirault <nicolas.lamirault@gmail.com>
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

# ====================================
# K I N D
# ====================================

##@ Kind

.PHONY: kind-install
kind-install: ## Install Kind
ifdef KIND_VERSION
	@echo "Found version $(KIND_VERSION)"
else
	@curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.10.0/kind-linux-amd64
	@chmod +x ./kind
	@mv ./kind /bin/kind
endif

.PHONY: kind-create
kind-create: guard-ENV ## Creates a local Kubernetes cluster (ENV=xxx)
	@echo -e "$(OK_COLOR)[$(APP)] Create Kubernetes cluster ${SERVICE}$(NO_COLOR)"
	@kind create cluster --name=$(CLUSTER) --config=hack/kind-config.yaml --wait 180s

.PHONY: kind-delete
kind-delete: guard-ENV ## Delete a local Kubernetes cluster (ENV=xxx)
	@echo -e "$(OK_COLOR)[$(APP)] Create Kubernetes cluster ${SERVICE}$(NO_COLOR)"
	@kind delete cluster --name=$(CLUSTER)

# ====================================
# K U B E R N E T E S
# ====================================

##@ Kubernetes

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
# C L O U D
# ====================================

##@ Cloud

.PHONY: cloud-gcp-credentials
cloud-gcp-credentials: guard-GCP_PROJECT_ID guard-GCP_SERVICE_ACCOUNT_NAME ## Generate credentials for GCP (GCP_PROJECT_ID=xxx GCP_SERVICE_ACCOUNT_NAME=xxx GCP_SERVICE_ACCOUNT_KEYFILE=xxx)
	@./hack/scripts/gcp.sh $(GCP_PROJECT_ID) $(GCP_SERVICE_ACCOUNT_NAME)

.PHONY: cloud-aws-credentials
cloud-aws-credentials: guard-AWS_ACCESS_KEY guard-AWS_SECRET_KEY ## Generate credentials for AWS (AWS_ACCESS_KEY=xxx AWS_SECRET_KEY=xxx)
	@./hack/scripts/aws.sh $(AWS_ACCESS_KEY) $(AWS_SECRET_KEY)

.PHONY: cloud-azure-credentials
cloud-azure-credentials: ## Generate credentials for Azure
	@./hack/scripts/azure.sh


# ====================================
# C R O S S P L A N E
# ====================================

##@ Crossplane

.PHONY: crossplane-controlplane
crossplane-controlplane: ## Install Crossplane using Helm
	@kubectl create namespace crossplane-system
	@helm repo add crossplane-stable https://charts.crossplane.io/stable
	@helm repo update
	@helm install crossplane --namespace crossplane-system crossplane-stable/crossplane --version $(HELM_CROSSPLANE_VERSION)

.PHONY: crossplane-provider
crossplane-provider: guard-CLOUD guard-ACTION ## Setup the Crossplane provider (CLOUD=xxx ACTION=xxx)
	@kustomize build krm/$(CLOUD)/provider | kubectl $(ACTION) -f -

.PHONY: crossplane-config
crossplane-config: guard-CLOUD guard-ACTION ## The Crossplane configuration (CLOUD=xxx ACTION=xxx)
	@kustomize build krm/$(CLOUD)/config | kubectl $(ACTION) -f -

.PHONY: crossplane-infra
crossplane-infra: guard-CLOUD guard-ACTION ## The Crossplane provider (CLOUD=xxx ACTION=xxx)
	@kustomize build krm/$(CLOUD)/infra | kubectl $(ACTION) -f -
