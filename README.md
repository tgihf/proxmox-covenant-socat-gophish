# covenant-nginx-gophish-proxmox

Provisioning and configuration automation for a small red team environment within a Proxmox Virtual Environment

## Prerequisites

* Ansible
* Terraform

## Prepare Ubuntu Cloud Init VM Template

```bash
cd preparation

# Source the image
wget https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img

# Transfer the image and create the template
ansible-playbook create-ubuntu-template.yml -i ../inventory/hosts --extra-vars "local_iso_path=$(pwd)/focal-server-cloudimg-amd64.img"
```

## Provision C2 Server

```bash
cd ../c2/
export PM_PASS="Proxmox Virtual Environment password goes here"
terraform init
terraform plan  # Enter Proxmox hostname/IP when prompted
terraform apply
```

## Configure C2 Server

```bash
ansible-playbook c2-config.yml -i ../inventory/hosts
```
