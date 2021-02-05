locals {
    config                  = yamldecode(file("./redirector-config.yml"))
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
data "template_file" "redirector_cloud_config" {
    count                   = local.config.redirector_count
    template                = file("../ubuntu-focal-cloud-config.yml")

    vars = {
        user                = local.config.redirector_user
        ssh_key             = file("~/.ssh/id_rsa.pub")
        hostname            = "${local.config.redirector_hostname}-${count.index}"
        domain              = local.config.redirector_domain
    }
}

# Create a local copy of the file, to transfer to Proxmox
resource "local_file" "redirector_cloud_config" {
    count                   = local.config.redirector_count
    content                 = data.template_file.redirector_cloud_config[count.index].rendered
    filename                = "./redirector_${count.index}_cloud_config.yml"
}

# Transfer the file to the Proxmox host
resource "null_resource" "redirector_cloud_config" {
    count                   = local.config.redirector_count
    connection {
        type                = "ssh"
        user                = "root"
        private_key         = file("~/.ssh/id_rsa")
        host                = local.config.proxmox_hostname_or_ip
    }

    provisioner "file" {
        source              = local_file.redirector_cloud_config[count.index].filename
        destination         = "/var/lib/vz/snippets/redirector_${count.index}_cloud_config.yml"
    }
}

# Create the VM
resource "proxmox_vm_qemu" "redirector" {
    depends_on = [
        null_resource.redirector_cloud_config,
    ]

    # Clone from ubuntu-focal-cloudinit
    count                   = local.config.redirector_count
    name                    = "redirector-${count.index}"
    desc                    = format("Apache mod_rewrite redirector #%s\nUser: %s\nIPv4: %s\n", count.index, local.config.redirector_user, format("%s.%s.%s.%s/%s", split(".", local.config.redirector_start_ip)[0], split(".", local.config.redirector_start_ip)[1], split(".", local.config.redirector_start_ip)[2], tonumber(split("/", split(".", local.config.redirector_start_ip)[3])[0]) + count.index, split("/", local.config.redirector_start_ip)[1]))
    target_node             = local.config.proxmox_node
    clone                   = "ubuntu-focal-cloudinit"
    os_type                 = "cloud-init"

    # Cloud init Options
    cicustom                = "user=local:snippets/redirector_${count.index}_cloud_config.yml"
    ipconfig0               = format("ip=%s,gw=%s", format("%s.%s.%s.%s/%s", split(".", local.config.redirector_start_ip)[0], split(".", local.config.redirector_start_ip)[1], split(".", local.config.redirector_start_ip)[2], tonumber(split("/", split(".", local.config.redirector_start_ip)[3])[0]) + count.index, split("/", local.config.redirector_start_ip)[1]), local.config.redirector_default_gateway)

    # Specifications
    cores                   = 2
    sockets                 = 1
    memory                  = 2048
    agent                   = 1

    # Set the boot disk parameters
    bootdisk                = "scsi0"
    scsihw                  = "virtio-scsi-pci"

    disk {
        size                = "7G"
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