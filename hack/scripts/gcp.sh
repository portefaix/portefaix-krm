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

echo_info "[GCP] Configure GCP provider"

[ -z "${GCP_PROJECT_ID}" ] && echo_fail "Environment variable GCP_PROJECT_ID not satisfied" && exit 1
[ -z "${GCP_SERVICE_ACCOUNT_NAME}" ] && echo_fail "Environment variable GCP_SERVICE_ACCOUNT_NAME not satisfied" && exit 1
SECRET_NAME=$1
NAMESPACE=$2

echo_info "[GCP] Project: ${GCP_PROJECT_ID} Service Account name: ${GCP_SERVICE_ACCOUNT_NAME}"

gcloud iam service-accounts create "${GCP_SERVICE_ACCOUNT_NAME}" \
		--project "${GCP_PROJECT_ID}" --display-name "${GCP_SERVICE_ACCOUNT_NAME}" \
		--description "Created by GCloud"

GCP_SERVICE_ACCOUNT_EMAIL="${GCP_SERVICE_ACCOUNT_NAME}@${GCP_PROJECT_ID}.iam.gserviceaccount.com"
GCP_SERVICE_ACCOUNT_KEYFILE=${GCP_PROJECT_ID}.json

gcloud projects add-iam-policy-binding "${GCP_PROJECT_ID}" \
    --member serviceAccount:"${GCP_SERVICE_ACCOUNT_EMAIL}" --role="roles/storage.admin"
gcloud projects add-iam-policy-binding "${GCP_PROJECT_ID}" \
    --member serviceAccount:"${GCP_SERVICE_ACCOUNT_EMAIL}" --role="roles/storage.objectAdmin"
gcloud projects add-iam-policy-binding "${GCP_PROJECT_ID}" \
    --member serviceAccount:"${GCP_SERVICE_ACCOUNT_EMAIL}" --role="roles/storage.objectViewer"
gcloud projects add-iam-policy-binding "${GCP_PROJECT_ID}" \
    --member serviceAccount:"${GCP_SERVICE_ACCOUNT_EMAIL}" --role="roles/compute.instanceAdmin.v1"
gcloud projects add-iam-policy-binding "${GCP_PROJECT_ID}" \
    --member serviceAccount:"${GCP_SERVICE_ACCOUNT_EMAIL}" --role="roles/compute.securityAdmin"
gcloud projects add-iam-policy-binding "${GCP_PROJECT_ID}" \
    --member serviceAccount:"${GCP_SERVICE_ACCOUNT_EMAIL}" --role="roles/compute.networkAdmin"
gcloud projects add-iam-policy-binding "${GCP_PROJECT_ID}" \
    --member serviceAccount:"${GCP_SERVICE_ACCOUNT_EMAIL}" --role="roles/resourcemanager.projectIamAdmin"
gcloud projects add-iam-policy-binding "${GCP_PROJECT_ID}" \
  --member serviceAccount:"${GCP_SERVICE_ACCOUNT_EMAIL}" --role="roles/iam.serviceAccountAdmin"
gcloud projects add-iam-policy-binding "${GCP_PROJECT_ID}" \
  --member serviceAccount:"${GCP_SERVICE_ACCOUNT_EMAIL}" --role="roles/iam.serviceAccountUser"
gcloud projects add-iam-policy-binding "${GCP_PROJECT_ID}" \
  --member serviceAccount:"${GCP_SERVICE_ACCOUNT_EMAIL}" --role="roles/iam.roleAdmin"
gcloud projects add-iam-policy-binding "${GCP_PROJECT_ID}" \
  --member serviceAccount:"${GCP_SERVICE_ACCOUNT_EMAIL}" --role="roles/iam.serviceAccountKeyAdmin"
gcloud projects add-iam-policy-binding "${GCP_PROJECT_ID}" \
  --member serviceAccount:"${GCP_SERVICE_ACCOUNT_EMAIL}" --role="roles/container.clusterAdmin"
gcloud projects add-iam-policy-binding "${GCP_PROJECT_ID}" \
  --member serviceAccount:"${GCP_SERVICE_ACCOUNT_EMAIL}" --role="roles/container.admin"
gcloud projects add-iam-policy-binding "${GCP_PROJECT_ID}" \
  --member serviceAccount:"${GCP_SERVICE_ACCOUNT_EMAIL}" --role="roles/secretmanager.admin"
gcloud projects add-iam-policy-binding "${GCP_PROJECT_ID}" \
  --member serviceAccount:"${GCP_SERVICE_ACCOUNT_EMAIL}" --role="roles/cloudkms.admin"
gcloud projects add-iam-policy-binding "${GCP_PROJECT_ID}" \
  --member serviceAccount:"${GCP_SERVICE_ACCOUNT_EMAIL}" --role="roles/cloudkms.cryptoKeyEncrypterDecrypter"
gcloud projects add-iam-policy-binding "${GCP_PROJECT_ID}" \
  --member serviceAccount:"${GCP_SERVICE_ACCOUNT_EMAIL}" --role="roles/dns.admin"
gcloud projects add-iam-policy-binding "${GCP_PROJECT_ID}" \
  --member serviceAccount:"${GCP_SERVICE_ACCOUNT_EMAIL}" --role="roles/iap.admin"
gcloud iam service-accounts keys create "./${GCP_SERVICE_ACCOUNT_KEYFILE}" \
		--project "${GCP_PROJECT_ID}" \
		--iam-account "${GCP_SERVICE_ACCOUNT_EMAIL}"

# base64 encode the GCP credentials
GCP_CREDS_ENCODED=$(base64 "${GCP_SERVICE_ACCOUNT_KEYFILE}" | tr -d "\n")

if [[ -z "${GCP_CREDS_ENCODED}" ]]; then
  echo_fail "error reading GCP credentials"
  exit 1
fi

echo_info "[Kubernetes] Creates secret for Crossplane GCP provider"
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: ${SECRET_NAME}
  namespace: ${NAMESPACE}
type: Opaque
data:
  credentials: ${GCP_CREDS_ENCODED}
EOF
