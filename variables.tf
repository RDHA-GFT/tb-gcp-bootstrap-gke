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
  default = 3
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
    }
  ]
}

variable "vpc_id" {
}

variable "subnet_id" {
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
  default = "n1-standard-4"
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
