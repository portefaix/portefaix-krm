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

FROM alpine:3.18@sha256:3ddf7bf1d408188f9849efbf4f902720ae08f5131bb39013518b918aa056d0de

LABEL maintainer="Nicolas Lamirault <nicolas.lamirault@gmail.com>" \
    org.opencontainers.image.title="Tools for Portefaix project" \
    org.opencontainers.image.description="Tools from the Kubernetes ecosystem" \
    org.opencontainers.image.authors="Nicolas Lamirault <nicolas.lamirault@gmail.com>" \
    org.opencontainers.image.vendor="Portefaix" \
    org.opencontainers.image.documentation="https://github.com/portefaix/portefaix" \
    org.opencontainers.image.licenses="Apache 2.0" \
    org.opencontainers.image.url="https://github.com/portefaix/portefaix" \
    org.opencontainers.image.source="https://github.com/portefaix/portefaix" \
    org.opencontainers.image.version="0.1.0"

RUN apk add --no-cache ca-certificates curl bash tar jq

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
