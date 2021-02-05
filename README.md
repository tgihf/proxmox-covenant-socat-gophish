# covenant-nginx-gophish-proxmox

Provisioning and configuration automation for a small red team environment within a Proxmox Virtual Environment

## Prerequisites

* Confirmed to work with Ansible v2.10.4
* Confirmed to work with Terraform v0.13.5

## Prepare Ubuntu Cloud Init VM Template

Ensure the IP address of the Proxmox Virtual Environment (PVE) server is placed under the `[pve]` tag in `inventory/hosts`, as so:

```bash
[pve]
192.168.1.100
```

Download the Ubuntu 20.04 Cloud Init image, transfer it to the PVE server, and create the Proxmox VM template.

```bash
cd preparation/

# Download the image
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

Ensure the IP address of the C2 server is placed under the `[c2]` tag in `inventory/hosts`, as so:

```text
[c2]
192.168.1.200
```

### Provision C2 Server

```bash
cd c2/
export PM_PASS="Proxmox Virtual Environment password goes here"
terraform init
terraform plan
terraform apply
```

### Configure C2 Server

```bash
# current working directory: c2/
ansible-playbook c2-configure.yml -i ../inventory/hosts
```

> The Covenant web interface will be accessible on port 7443 via HTTPS.

## socat Redirector(s)

### socat Redirector(s) Configuration Variables

Modify the socat Redirector(s) configuration variables as necessary.

Pay careful attention to the **redirector_start_ip** variable. Terraform will provision the number of redirectors you tell it to in the **redirector_count** variable. Each redirector will be assigned an IP address incrementally, starting from **redirector_start_ip**.

```bash
redirector/redirector-config.yml
```

Ensure the IP address of the redirector(s) is placed under the `[redirector]` tag in `inventory/hosts`, as so:

```text
[redirector]
192.168.1.50
192.168.1.51
192.168.1.52
```

### Provision socat Redirector(s)

```bash
cd redirector/
export PM_PASS="Proxmox Virtual Environment password goes here"
terraform init
terraform plan
tarraform apply
```

### Configure socat Redirector(s)

```bash
# current working directory: redirector/
ansible-playbook redirector-configure.yml -i ../inventory/hosts
```

## Phishing Server

### Phishing Server Configuration Variables

Modify the phishing server configuration variables as necessary.

```bash
phishing/phishing-config.yml
```

Ensure the IP address of the Phishing server is placed under the `[phishing]` tag in `inventory/hosts`, as so:

```text
[phishing]
192.168.1.250
```

### Provision Phishing Server

```bash
cd phishing/
export PM_PASS="Proxmox Virtual Environment password goes here"
terraform init
terraform plan
terraform apply
```

### Configure Phishing Server

```bash
# current working directory: phishing/
ansible-playbook phishing-configure.yml -i ../inventory/hosts
```

> This playbook will output the administrator credentials used to login to the GoPhish administrative interface on port 3333 via HTTPS.
