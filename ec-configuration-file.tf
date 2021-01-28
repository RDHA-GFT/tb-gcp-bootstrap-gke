
# Copyright 2019 The Tranquility Base Authors
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
/*
resource "local_file" "ec_config_map" {
  content  = local.ec_config_map_configuration
  filename = "./ec-config.yaml"
}
//todo need to change to pull in project create service
locals {
  ec_config_map_configuration = <<FILE
apiVersion: v1
kind: ConfigMap
metadata:
  name: ec-config
  namespace: ssp
data:
  ec-config.yaml: |
    activator_folder_id: ${var.folder_id}
    billing_account: ${var.billing_id}
    region: ${var.region}
    terraform_state_bucket: ${var.state_bucket_name}
    env_data: input.tfvars
    ec_project_name: ${var.project_id}
    shared_vpc_host_project: ${var.project_id}
    shared_network_name: ${var.vpc_name}
    shared_networking_id: ${var.vpc_id}
    activator_terraform_code_store: ${google_sourcerepo_repository.activator-terraform-code-store.name}
    tb_discriminator: ${var.discriminator}
    jenkins_url: PLACEHOLDER
FILE

}

*/