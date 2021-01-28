# Copyright 2021 The Tranquility Base Authors
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

variable "remove_default_node_pool" {
  type = bool
  default = true
}

variable "project_id" {
}

variable "region" {
}

variable "initial_node_count" {
  type = number
  default = 1
}

variable "maintenance_start_time" {
  type    = string
  default = "02:00"
}

variable "pod_mon_service" {
  type    = string
  default = "monitoring.googleapis.com/kubernetes"
}

variable "pod_log_service" {
  type    = string
  default = "logging.googleapis.com/kubernetes"
}

variable "default_max_pods_per_node" {
  description = "The maximum number of pods to schedule per node"
  default = 110
}

variable "master_authorized_networks" {
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = [
    {
      cidr_block   = "10.0.0.0/8",
      display_name = "mgmt-1"
    },
    {
      cidr_block   = "10.0.6.0/24",
      display_name = "proxy-subnet"
    },
    {
      cidr_block   = "172.16.0.18/32",
      display_name = "initial-admin-ip"
    }
  ]
}

variable "vpc_name" {
}

variable "vpc_id" {

}
variable "subnet_name" {
}

variable "discriminator" {
}

variable "billing_id" {
}

variable "state_bucket_name" {
}

variable "pod_network_name" {
  type        = string
  default     = "gke-pods-snet"
  description = "Name for the gke pod network"
}

variable "service_network_name" {
  type        = string
  default     = "gke-services-snet"
  description = "Name for the gke service network"
}

variable "cluster_master_cidr" {
  type = string
  default = "172.16.0.0/28"
}

variable "node_pool_name" {
  description = "The cluster pool name"
  default = "gke-ec-node-pool"

}

variable "autoscaling_min_nodes" {
  type = string
  default = 1
}

variable "autoscaling_max_nodes" {
  type = string
  default = 3
}

variable "node_machine_type" {
  type    = string
  default = "e2-standard-4"
}

variable "node_disk_size_gb" {
  type    = string
  default = "30"
}

variable "node_oauth_scopes" {
  type = string
  default = "https://www.googleapis.com/auth/cloud-platform"
}

variable "kubernetes_version" {
  default     = "latest"
  description = "Master node minimal version"
  type        = string
}

variable "istio_status" {
  type    = bool
  default = "true"
}

variable "istio_permissive_mtls" {
  type    = string
  default = "false"
}

variable "issue_client_certificate" {
  default = false
}

variable "horizontal_pod_autoscaling" {
  default = false
}

variable "random_id" {
}

#################### variables needed for modules ####################

# EC Deployment
variable "eagle_console_yaml_path" {
  default     = "./modules/kubernetes_yaml/eagle_console.yaml"
  description = "Path to the yaml file describing the eagle console resources"
  type        = string
}

variable "ec_repository_name" {
  default     = "EC-activator-tf"
  description = "Repository name used to store activator code"
  type        = string
}

variable "endpoint_file" {
  type        = string
  description = "Path to local file that will be created to store istio endpoint. The file will be created in the terraform run or overwritten (if exists). You need to ensure that directory in which it's created exists"
  default     = "/opt/tb/repo/tb-gcp-tr/gae-self-service-portal/endpoint-meta.json"
}

variable "ec_iam_service_account_roles" {
  default = [
    "roles/resourcemanager.folderAdmin",
    "roles/resourcemanager.projectCreator",
    "roles/compute.xpnAdmin",
    "roles/resourcemanager.projectDeleter",
    "roles/billing.projectManager",
    "roles/owner",
    "roles/compute.networkAdmin",
    "roles/datastore.owner",
    "roles/browser",
    "roles/resourcemanager.projectIamAdmin"
  ]
  description = "Roles attached to service account"
  type        = list(string)
}

#iTop deployment
variable "itop_database_user_name" {
  description = "iTop's database user account name"
  default     = "itop"
  type        = string
}

variable "ec_ui_source_bucket" {
  default     = "tranquility-base-ui"
  description = "GCS Bucket hosting Self Service Portal Angular source code."
  type        = string
}

variable "private_dns_name" {
  type        = string
  default     = "private-shared"
  description = "Name for private DNS zone in the shared vpc network"
}

variable "private_dns_domain_name" {
  type        = string
  default     = "tranquilitybase-demo.io." # domain requires . to finish
  description = "Domain name for private DNS in the shared vpc network"
}
## DAC Services ##########
# Namespace creations
variable "sharedservice_namespace_yaml_path" {
  default     = "/home/amce/tb-gcp-management-plane/namespaces.yaml"
  description = "Path to the yaml file to create namespaces on the shared gke-ec cluster"
  type        = string
}

# StorageClasses creation
variable "sharedservice_storageclass_yaml_path" {
  default     = "../kubernetes_yaml/storageclasses.yaml"
  description = "Path to the yaml file to create storageclasses on the shared gke-ec cluster"
  type        = string
}

# Jenkins install
variable "sharedservice_jenkinsmaster_yaml_path" {
  default     = "./jenkins-master.yaml"
  description = "Path to the yaml file to deploy Jenkins on the shared gke-ec cluster"
  type        = string
}

variable "folder_id" {
}
