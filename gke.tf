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

module "dac-secret" {
  source = "./modules/dac-secret"

  content = module.SharedServices_namespace_creation.id
  context_name = module.k8s-ec_context.context_name

  depends_on = [module.SharedServices_namespace_creation, module.k8s-ec_context]
}

module "k8s-ec_context" {
  source = "./modules/k8s-context"

  cluster_name    = local.cluster_name
  region          = var.region
  cluster_project = var.project_id

  depends_on = [module.gke]
}

module "SharedServices_namespace_creation" {
  source = "./modules/start_service"

  k8s_template_file = var.sharedservice_namespace_yaml_path
  cluster_context   = module.k8s-ec_context.context_name

  depends_on = [module.k8s-ec_context]
}

resource "null_resource" "kubernetes_service_account_key_secret" {
  triggers = {
    content = module.SharedServices_namespace_creation.id
    k8_name = module.k8s-ec_context.context_name
  }

  provisioner "local-exec" {
    command = "echo 'kubectl --context=${module.k8s-ec_context.context_name} create secret generic ec-service-account -n ssp --from-file=${local_file.ec_service_account_key.filename}' | tee -a ./kube.sh"
  }

  provisioner "local-exec" {
    command = "echo 'kubectl --context=${self.triggers.k8_name} delete secret ec-service-account' -n ssp | tee -a ./kube.sh"
    when    = destroy
  }
}

resource "null_resource" "kubernetes_jenkins_service_account_key_secret" {
  triggers = {
    content = module.SharedServices_namespace_creation.id
    k8_name = module.k8s-ec_context.context_name
  }

  provisioner "local-exec" {
    command = "echo 'kubectl --context=${module.k8s-ec_context.context_name} create secret generic ec-service-account -n cicd --from-file=${local_file.ec_service_account_key.filename}' | tee -a ./kube.sh"
  }

  provisioner "local-exec" {
    command = "echo 'kubectl --context=${self.triggers.k8_name} delete secret ec-service-account' -n cicd | tee -a ./kube.sh"
    when    = destroy
  }
}

module "SharedServices_storageclass_creation" {
  source = "./modules/start_service"

  k8s_template_file = var.sharedservice_storageclass_yaml_path
  cluster_context   = module.k8s-ec_context.context_name

  depends_on = [module.k8s-ec_context]
}

module "SharedServices_jenkinsmaster_creation" {
  source = "./modules/start_service"

  k8s_template_file = var.sharedservice_jenkinsmaster_yaml_path
  cluster_context   = module.k8s-ec_context.context_name
  # Jenkins Deployment depends on the ec-service-account secret creation

  depends_on = [module.dac-secret, null_resource.kubernetes_jenkins_service_account_key_secret]
}
/*
//todo figure out where these values are used
module "SharedServices_configuration_file" {
  source = "./modules/start_service"

  k8s_template_file = local_file.ec_config_map.filename
  cluster_context   = module.k8s-ec_context.context_name

  depends_on = [module.k8s-ec_context]
}
*/


module "SharedServices_ec" {
  source = "./modules/start_service"

  k8s_template_file = var.eagle_console_yaml_path
  cluster_context   = module.k8s-ec_context.context_name

  depends_on = [module.dac-secret, module.k8s-ec_context]
}


##### FOR TESTING ONLY, WILL BE DELETED #####

data "google_compute_image" "centos_image" {
  family  = "centos-7"
  project = "centos-cloud"
}

resource "google_compute_instance" "squid_proxy_instance" {
  project = var.project_id
  name    = "tb-kube-proxy-template"
  zone    = "europe-west1-a"

  machine_type = "n1-standard-2"

  // boot disk
  boot_disk {
    source = data.google_compute_image.centos_image.self_link
  }

  network_interface {
    subnetwork = "projects/${var.project_id}/regions/${var.region}/subnetworks/bootstrapsubnet"
  }

  service_account {
    email  = local.sa_email
    scopes = ["cloud-platform"]
  }

  metadata_startup_script = "./squid_startup.sh"

  // make sure the project is attached and can see the shared VPC network before referencing one of it's subnetworks
  depends_on = [module.gke]
}

##############################################