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

module "gke" {
  source                     = "terraform-google-modules/kubernetes-engine/google//modules/beta-private-cluster"
  version                    = "12.3.0"

  region                     = var.region
  network                    = var.vpc_name
  subnetwork                 = var.subnet_name
  project_id                 = var.project_id
  name                       = local.cluster_name
  ip_range_pods              = var.pod_network_name
  ip_range_services          = var.service_network_name
  enable_private_endpoint    = true
  enable_private_nodes       = true
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
      service_account    = local.sa_email
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
      local.cluster_name
    ]
  }
}

resource "google_service_account" "proxy-sa-res" {
  account_id   = "proxy-sa"
  display_name = "proxy-sa"
  project      = var.project_id
}

locals {
  service_account_name = "serviceAccount:${google_service_account.proxy-sa-res.account_id}@${var.project_id}.iam.gserviceaccount.com"
}

resource "google_folder_iam_member" "sa-folder-admin-role" {
  count      = length(var.main_iam_service_account_roles)
  folder     = "folders/${var.folder_id}"
  role       = element(var.main_iam_service_account_roles, count.index)
  member     = local.service_account_name
  depends_on = [google_service_account.proxy-sa-res]
}

resource "google_compute_firewall" "allow_proxy_http_ingress" {
  name    = "allow-proxy-http-ingress"
  network = var.vpc_name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = [80, 443, 8008, 8080, 8443]
  }

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }

  source_service_accounts = [
    google_service_account.proxy-sa-res.email
  ]
}

resource "null_resource" "k8s_config" {
  provisioner "local-exec" {
    command = <<EOT
    gcloud beta container clusters get-credentials "${local.cluster_name}" --region="${var.region}" --project="${var.project_id}" --internal-ip
    EOT
  }
  depends_on = [module.gke]
}

data "google_compute_image" "centos_image" {
  family  = "centos-7"
  project = "centos-cloud"
}

resource "google_compute_instance_template" "squid_proxy_template" {
  project = var.project_id
  name    = "tb-kube-proxy-template"

  machine_type = "n1-standard-2"

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  // boot disk
  disk {
    source_image = data.google_compute_image.centos_image.self_link
  }

  network_interface {
    subnetwork = "projects/${var.project_id}/regions/${var.region}/subnetworks/${var.subnet_name}"
  }

  service_account {
    email  = google_service_account.proxy-sa-res.email
    scopes = var.scopes
  }

  metadata_startup_script = file("${path.module}/squid_startup.sh")

  // make sure the project is attached and can see the shared VPC network before referencing one of it's subnetworks
  depends_on = [module.gke]
}

resource "google_compute_instance_group_manager" "squid_proxy_group" {
  project            = var.project_id
  base_instance_name = "tb-kube-proxy"
  zone               = var.region_zone

  version {
    instance_template = google_compute_instance_template.squid_proxy_template.self_link
    name              = "tb-kube-proxy-template"
  }

  target_size = 1
  name        = "tb-squid-proxy-group"

  depends_on = [module.gke, module.service-accounts]
}

resource "null_resource" "start-iap-tunnel" {

  provisioner "local-exec" {
    command = <<EOF
echo '
INSTANCE=$(gcloud compute instance-groups managed list-instances tb-squid-proxy-group --project=${var.project_id} --zone ${var.region_zone} --format="value(instance.scope(instances))")
gcloud compute start-iap-tunnel $INSTANCE 3128 --local-host-port localhost:3128 --project ${var.project_id} --zone ${var.region_zone} > /dev/null 2>&1 &
TUNNELPID=$!
sleep 10
export HTTPS_PROXY="localhost:3128"'
EOF
  }
  depends_on = [google_compute_instance_group_manager.squid_proxy_group]
}

/*
resource "null_resource" "flux_installed" {
  provisioner "local-exec" {
    command = <<EOT
    kubectl apply -f https://github.com/fluxcd/flux2/releases/latest/download/install.yaml
    EOT
  }
  depends_on = [null_resource.start-iap-tunnel]
}

*/