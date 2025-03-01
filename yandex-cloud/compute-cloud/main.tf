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


resource "yandex_compute_instance" "core" {
  name = "core"

  resources {
    cores  = 16
    memory = 16
  }

  boot_disk {
    initialize_params {
      image_id = "fd80bm0rh4rkepi5ksdi"
      size     = 40
      type     = "network-ssd"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}

resource "yandex_vpc_network" "network-1" {
  name = "network1"
}

resource "yandex_vpc_subnet" "subnet-1" {
  name           = "subnet1"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.network-1.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

resource "null_resource" "delay" {
  provisioner "local-exec" {
    command = "sleep 200"
  }
}


output "internal_ip_address_core" {
  value = yandex_compute_instance.core.network_interface.0.ip_address
}

output "external_ip_address_core" {
  value = yandex_compute_instance.core.network_interface.0.nat_ip_address
}