
locals {
    config                  = yamldecode(file("./c2-config.yml"))
}

terraform {
    required_providers {
      proxmox = {
          source = "Telmate/proxmox"
      }
    }
}

provider "proxmox" {
    pm_api_url              = "https://${local.config.proxmox_hostname_or_ip}:8006/api2/json"
    pm_user                 = local.config.proxmox_user
    pm_otp                  = ""
    pm_tls_insecure         = "true"
}

# Source the Cloud Init config file
data "template_file" "c2_cloud_config" {
    template                = file("../ubuntu-focal-cloud-config.yml")

    vars = {
        user                = local.config.c2_user
        ssh_key             = file("~/.ssh/id_rsa.pub")
        hostname            = local.config.c2_hostname
        domain              = local.config.c2_domain
    }
}

# Create a local copy of the file, to transfer to Proxmox
resource "local_file" "c2_cloud_config" {
    content                 = data.template_file.c2_cloud_config.rendered
    filename                = "./c2_cloud_config.yml"
}

# Transfer the file to the Proxmox host
resource "null_resource" "c2_cloud_config" {
    count                   = 1
    connection {
        type                = "ssh"
        user                = "root"
        private_key         = file("~/.ssh/id_rsa")
        host                = local.config.proxmox_hostname_or_ip
    }

    provisioner "file" {
        source              = local_file.c2_cloud_config.filename
        destination         = "/var/lib/vz/snippets/c2_cloud_config.yml"
    }
}

# Create the VM
resource "proxmox_vm_qemu" "c2" {

    # Clone from ubuntu-focal-cloudinit
    count                   = 1
    name                    = "c2"
    desc                    = "C2 Server.\nUser: ${local.config.c2_user}.\nIPv4: ${local.config.c2_ip}.\n"
    target_node             = local.config.proxmox_node
    clone                   = "ubuntu-focal-cloudinit"
    os_type                 = "cloud-init"

    # Cloud init Options
    cicustom                = "user=local:snippets/c2_cloud_config.yml"
    ipconfig0               = "ip=${local.config.c2_ip},gw=${local.config.c2_default_gateway}"

    # Specifications
    cores                   = 3
    sockets                 = 1
    memory                  = 2048
    agent                   = 1

    # Set the boot disk parameters
    bootdisk                = "scsi0"
    scsihw                  = "virtio-scsi-pci"

    disk {
        size                = "10G"
        type                = "scsi"
        storage             = "vm-storage"
        iothread            = 1
    }

    network {
        model               = "virtio"
        bridge              = "vmbr0"
    }

    # Ignore changes to the network
    # MAC address generated on every apply, causing Terraform to think this needs to be rebuilt on every apply
    lifecycle {
        ignore_changes = [
            network
        ]
    }
}
