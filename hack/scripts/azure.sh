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

echo_info "[Azure] Configure Azure provider"

[ -z "${AZURE_SUBSCRIPTION_ID}" ] && echo_fail "Azure subscription not satisfied" && exit 1
SECRET_NAME=$1
NAMESPACE=$2

SCOPES="/subscriptions/${AZURE_SUBSCRIPTION_ID}"

CREDS_FILE="creds.json"

az ad sp create-for-rbac --role Owner --scopes "${SCOPES}" --sdk-auth -n "crossplane-krm" > ${CREDS_FILE}
if [ ! -f "${CREDS_FILE}" ]; then
  echo_fail "Azure configuration file ${CREDS_FILE} not found"
  exit 1
fi
cat ${CREDS_FILE}

AZURE_CLIENT_ID=$(jq -r .clientId < "${CREDS_FILE}")
echo_info "[Azure] Add permission to client: ${AZURE_CLIENT_ID}"

AZURE_AD_ID="00000002-0000-0000-c000-000000000000"

echo_info "[Azure] Add required Azure Active Directory permissions"
az ad app permission add --id "${AZURE_CLIENT_ID}" \
   --api "${AZURE_AD_ID}" \
   --api-permissions 1cda74f2-2616-4834-b122-5cb1b07f8a59=Role \
   --api-permissions 78c8a3c8-a07e-4b9e-af1b-b5ccab50a175=Role

echo_info "[Azure] Grant the permissions"
az ad app permission grant --id "${AZURE_CLIENT_ID}" --api "${AZURE_AD_ID}" --scope "${SCOPES}"

echo_info "[Azure] Grant admin consent to the service principal"
az ad app permission admin-consent --id "${AZURE_CLIENT_ID}"

AZURE_CREDS_ENCODED=$(base64 "${CREDS_FILE}" | tr -d "\n")
if [[ -z "${AZURE_CREDS_ENCODED}" ]]; then
  echo_fail "error reading credentials from Azure CLI output"
  exit 1
fi

echo_info "[Kubernetes] Creates secret for Crossplane Azure provider"
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: ${SECRET_NAME}
  namespace: ${NAMESPACE}
type: Opaque
data:
  credentials: ${AZURE_CREDS_ENCODED}
EOF

rm "${CREDS_FILE}"
