module "gke" {
  source                     = "terraform-google-modules/kubernetes-engine/google//modules/beta-private-cluster"

  region                     = var.region
  network                    = var.host_network
  subnetwork                 = var.host_subnetwork
  project_id                 = var.project_id
  name                       = var.cluster_name
  ip_range_pods              = var.pod_network_name
  ip_range_services          = var.service_network_name
  enable_private_endpoint    = false
  enable_private_nodes       = false
  remove_default_node_pool   = var.remove_default_node_pool
  initial_node_count         = var.initial_node_count
  maintenance_start_time     = var.maintenance_start_time
  monitoring_service         = var.pod_mon_service
  logging_service            = var.pod_log_service
  basic_auth_username        = ""
  basic_auth_password        = ""
  issue_client_certificate   = var.issue_client_certificate
  default_max_pods_per_node  = var.default_max_pods_per_node
  master_authorized_networks = var.master_authorized_networks
  master_ipv4_cidr_block     = var.cluster_master_cidr
  horizontal_pod_autoscaling = var.horizontal_pod_autoscaling
  kubernetes_version         = var.kubernetes_version
  istio                      = var.istio_status
  istio_auth                 = var.istio_permissive_mtls == "true" ? "AUTH_NONE" : "AUTH_MUTUAL_TLS"

  node_pools = [
    {
      name               = var.node_pool_name
      initial_node_count = var.initial_node_count
      min_count          = var.autoscaling_min_nodes
      max_count          = var.autoscaling_max_nodes
      machine_type       = var.node_machine_type
      disk_size_gb       = var.node_disk_size_gb
      service_account    = var.node_service_account
    }
  ]

  node_pools_oauth_scopes = {
    all = []

    default-node-pool = [
      var.node_oauth_scopes,
    ]
  }

  node_pools_tags = {
    all = []

    default-node-pool = [
      "gke-private",
      var.cluster_name
    ]
  }
}