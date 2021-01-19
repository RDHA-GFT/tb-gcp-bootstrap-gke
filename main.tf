locals {
  prefix  = var.random_id
  cluster_name = format("%s-%s", "gke-ec", local.prefix)
  sa_name = "kubernetes-ec"
}