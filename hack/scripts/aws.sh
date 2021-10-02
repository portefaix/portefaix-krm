#! /usr/bin/env bash

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

reset_color="\\e[0m"
color_red="\\e[31m"
color_green="\\e[32m"
color_blue="\\e[36m";

declare -r this_dir=$(cd $(dirname ${BASH_SOURCE[0]}) && pwd)
declare -r root_dir=$(cd ${this_dir}/../.. && pwd)

function echo_fail { echo -e "${color_red}✖ $*${reset_color}"; }
function echo_success { echo -e "${color_green}✔ $*${reset_color}"; }
function echo_info { echo -e "${color_blue}$*${reset_color}"; }

echo_info "[AWS] Configure AWS provider"
aws_profile=default
# $(echo -e "[default]\naws_access_key_id = $(aws configure get aws_access_key_id --profile $aws_profile)\naws_secret_access_key = $(aws configure get aws_secret_access_key --profile $aws_profile)" | base64  | tr -d "\n")
AWS_CREDS_ENCODED=$(cat <<EOF | base64 | tr -d "\n"
[default]
aws_access_key_id = $(aws configure get aws_access_key_id --profile ${aws_profile})
aws_secret_access_key = $(aws configure get aws_secret_access_key --profile ${aws_profile})
EOF
)

if [[ -z "${AWS_CREDS_ENCODED}" ]]; then
  echo_fail "error reading credentials from aws config"
  exit 1
fi

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: crossplane-aws-credentials
  namespace: crossplane-system
type: Opaque
data:
  key: ${AWS_CREDS_ENCODED}
EOF

# echo_info "[Kubernetes] Setup Crossplane AWS provider"
# kubectl apply -f ${this_dir}/provider-aws.yaml
# kubectl wait --for condition=Healthy  providers.pkg.crossplane.io/aws
# kubectl apply -f ${this_dir}/providerconfig-aws.yaml