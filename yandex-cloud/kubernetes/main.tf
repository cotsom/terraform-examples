terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
    local = {
      source = "hashicorp/local"
      version = "2.2.0"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  zone = "ru-central1-b"
}

//
// Create a new Managed Kubernetes zonal Cluster.
//
resource "yandex_kubernetes_cluster" "zonal_cluster" {
  name        = "name"
  description = "description"

  network_id = yandex_vpc_network.network_resource_name.id


  master {
    version = "1.30"
    zonal {
      zone      = yandex_vpc_subnet.subnet_resource_name.zone
      subnet_id = yandex_vpc_subnet.subnet_resource_name.id
    }

    public_ip = true

    security_group_ids = ["${yandex_vpc_security_group.security_group_name.id}"]

    maintenance_policy {
      auto_upgrade = true

      maintenance_window {
        start_time = "15:00"
        duration   = "3h"
      }
    }

    master_logging {
      enabled                    = true
      log_group_id               = yandex_logging_group.log_group_resource_name.id
      kube_apiserver_enabled     = true
      cluster_autoscaler_enabled = true
      events_enabled             = true
      audit_enabled              = true
    }
  }

  service_account_id      = yandex_iam_service_account.service_account_resource_name.id
  node_service_account_id = yandex_iam_service_account.node_service_account_resource_name.id

  labels = {
    my_key       = "my_value"
    my_other_key = "my_other_value"
  }

  release_channel         = "RAPID"
  network_policy_provider = "CALICO"

  kms_provider {
    key_id = yandex_kms_symmetric_key.kms_key_resource_name.id
  }

  depends_on = [
    yandex_resourcemanager_folder_iam_member.ServiceAccountResourceName,
    yandex_resourcemanager_folder_iam_member.NodeServiceAccountResourceName
  ]
}

resource "yandex_vpc_network" "network_resource_name" {
  name = "my-network"
}

resource "yandex_vpc_subnet" "subnet_resource_name" {
  name           = "my-subnet"
  zone          = "ru-central1-b"
  network_id    = yandex_vpc_network.network_resource_name.id
  v4_cidr_blocks = ["10.0.0.0/24"]
}


resource "yandex_vpc_security_group" "security_group_name" {
  name       = "my-security-group"
  network_id = yandex_vpc_network.network_resource_name.id

  ingress {
    protocol       = "TCP"
    description    = "Allow SSH"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port          = 22
  }
}

resource "yandex_iam_service_account" "service_account_resource_name" {
  name = "k8s-service-account"
}

resource "yandex_iam_service_account" "node_service_account_resource_name" {
  name = "k8s-node-service-account"
}


resource "yandex_kms_symmetric_key" "kms_key_resource_name" {
  name              = "k8s-key"
  default_algorithm = "AES_256"
}

resource "yandex_logging_group" "log_group_resource_name" {
  name = "k8s-log-group"
}

resource "yandex_resourcemanager_folder_iam_member" "ServiceAccountResourceName" {
  folder_id = var.folder_id
  role      = "k8s.clusters.agent"
  member    = "serviceAccount:${yandex_iam_service_account.service_account_resource_name.id}"
}
resource "yandex_resourcemanager_folder_iam_member" "ServiceAccountResourceNameVpcRole" {
  folder_id = var.folder_id
  role      = "vpc.publicAdmin"
  member    = "serviceAccount:${yandex_iam_service_account.service_account_resource_name.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "ServiceAccountResourceNameLoggingRole" {
  folder_id = var.folder_id
  role      = "logging.writer"
  member    = "serviceAccount:${yandex_iam_service_account.service_account_resource_name.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "NodeServiceAccountResourceName" {
  folder_id = var.folder_id
  role      = "container-registry.images.puller"
  member    = "serviceAccount:${yandex_iam_service_account.node_service_account_resource_name.id}"
}