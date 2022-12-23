#! /usr/bin/env bash

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

reset_color="\\e[0m"
color_red="\\e[31m"
color_green="\\e[32m"
color_blue="\\e[36m";

# declare -r this_dir=$(cd $(dirname ${BASH_SOURCE[0]}) && pwd)
# declare -r root_dir=$(cd ${this_dir}/../.. && pwd)

function echo_fail { echo -e "${color_red}✖ $*${reset_color}"; }
function echo_success { echo -e "${color_green}✔ $*${reset_color}"; }
function echo_info { echo -e "${color_blue}$*${reset_color}"; }

echo_info "[Azure] Azure Service Operator"

[ -z "${AZURE_TENANT_ID}" ] && echo_fail "Environment variable AZURE_TENANT_ID not satisfied" && exit 1
[ -z "${AZURE_SUBSCRIPTION_ID}" ] && echo_fail "Environment variable AZURE_SUBSCRIPTION_ID not satisfied" && exit 1
SECRET_NAME=$1
NAMESPACE=$2

az ad sp create-for-rbac -n azure-service-operator --role contributor \
    --scopes "/subscriptions/${AZURE_SUBSCRIPTION_ID}" > aso.json

AZURE_CLIENT_ID=$(jq -r .appId < aso.json)
AZURE_CLIENT_SECRET=$(jq -r .password < aso.json)

echo_info "[Kubernetes] Azure: Create secret ${SECRET_NAME} into ${NAMESPACE}"
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
 name: ${SECRET_NAME}
 namespace: ${NAMESPACE}
stringData:
  AZURE_SUBSCRIPTION_ID: "${AZURE_SUBSCRIPTION_ID}"
  AZURE_TENANT_ID: "${AZURE_TENANT_ID}"
  AZURE_CLIENT_ID: "${AZURE_CLIENT_ID}"
  AZURE_CLIENT_SECRET: "${AZURE_CLIENT_SECRET}"
  AZURE_CLOUD_ENV: "AzurePublicCloud"
  AZURE_USE_MI: "1"
  AZURE_OPERATOR_KEYVAULT: ""
  AZURE_SECRET_NAMING_VERSION: "2"
  PURGE_DELETED_KEYVAULT_SECRETS: "false"
  RECOVER_SOFT_DELETED_KEYVAULT_SECRETS: "true"
EOF
echo_success "[Azure] Secret deployed"
