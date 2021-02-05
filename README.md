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

## C2 Server

### C2 Configuration Variables

Modify the C2 configuration variables as necessary.

```bash
c2/c2-config.yml
```

Ensure the IP address of the C2 server is placed under the [c2] tag in inventory/hosts, as so:

```text
[c2]
192.168.1.200
```

### Provision C2 Server

```bash
cd ../c2/
export PM_PASS="Proxmox Virtual Environment password goes here"
terraform init
terraform plan
terraform apply
```

### Configure C2 Server

```bash
ansible-playbook c2-configure.yml -i ../inventory/hosts
```

## socat Redirector(s)

### socat Redirector(s) Configuration Variables

Modify the socat Redirector(s) configuration variables as necessary.

Pay careful attention to the **redirector_start_ip** variable. Terraform will provision the number of redirectors you tell it to in the **redirector_count** variable. Each redirector will be assigned an IP address incrementally, starting from **redirector_start_ip**.

```bash
redirector/redirector-config.yml
```

Ensure the IP address of the redirector(s) is placed under the [redirector] tag in inventory/hosts, as so:

```text
[redirector]
192.168.1.50
192.168.1.51
192.168.1.52
```

### Provision socat Redirector(s)

```bash
cd ../redirector/
export PM_PASS="Proxmox Virtual Environment password goes here"
terraform init
terraform plan
tarraform apply
```

### Configure socat Redirector(s)

```bash
ansible-playbook redirector-configure.yml -i ../inventory/hosts
```
