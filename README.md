## What is MinIO Ansible Playbook?
It is ansible playbook to deploy Distributed MinIO SNMD ( Single Node Multi Devices ) and MNMD ( Multi Nodes Multi Devices ) with HAProxy and Keepalived on Baremetal, Virtual Machines and Cloud Infrastructure.
The main purpose of this project is actually very simple. Because there are many jobs to install different kind of MinIO versions and reproduce issues & test features as a support
engineer. I just want to spend less time for it.

If you are working with MinIO such as Developer, Administrator, Field Engineer or Storage Administrator you could also utilize it very conviently as saving time.

<p align="center">
<img src="https://github.com/rokmc756/MinIO/blob/main/roles/mnmd/images/minio-architecture.webp" width="80%" height="80%">
</p>

## Supported MiniIO Versions
* MinIO Version and Release Date: 20250422221226.0.0-1. Because the higher version of it requires license.

## Supported Platform and OS
* Virtual Machines
* Baremetal
* RHEL/CentOS/Rocky Linux 9.x so far

## Prerequisite
* MacOS or Fedora/CentOS/RHEL should have installed ansible as ansible host.
* Supported OS for ansible target host should be prepared with package repository configured such as yum, dnf and apt

## Prepare ansible host to setup MinIO by ansible playbook
* MacOS
```yaml
$ xcode-select --install
$ brew install ansible
$ brew install https://raw.githubusercontent.com/kadwanev/bigboybrew/master/Library/Formula/sshpass.rb
```
* Fedora/CentOS/RHEL
```yaml
$ sudo yum install ansible
$ sudo yum install -y python3-netaddr
```

## Prepareing OS
* Configure Yum / Local & EPEL Repostiory

## Clone / Configure / Run MinIO Ansible Playbook
```yaml
$ git clone https://github.com/rokmc756/MinIO
$ cd MinIO
$ vi Makefile
~~ snip
ANSIBLE_HOST_PASS="changeme"    # It should be changed with password of user in ansible host that minio would be run.
ANSIBLE_TARGET_PASS="changeme"  # It should be changed with password of sudo user in managed nodes that minio would be installed.
~~ snip
```

## For MinIO SNMD ( Single Node Multi Devices )
#### 1) The Architecure of MinIO SNMD
```
            +--------------------+
            |     S3 Client      |
            +--------------------+
                       |
                       v
      https://rk9-node01.jtest.pivotal.io
                       |
                       v
    +------------------------------------+
    |             MinIO Server           |
    |            ( Single Node )         |
    +------------------------------------+
       |          |         |         |
       v          v         v         v
   +-------+  +-------+ +-------+ +-------+
   | Disk1 |  | Disk2 | | Disk3 | | Disk4 |  (XFS/ext4/ZFS)
   +-------+  +-------+ +-------+ +-------+

<--- All drives participate in erasure coding --->
```

#### 2) Configure Inventory for MinIO SNMD 
```yaml
[all:vars]
ssh_key_filename="id_rsa"
remote_machine_username="jomoon"
remote_machine_password="changeme"

[workers]
rk9-node01 ansible_ssh_host=192.168.2.171
```

#### 3) Configure Variables
```yaml
$ vi roles/snmd/defaults/main.yml
---
minio_download: false
~~ snip
minio_access_key: 'admin'
minio_secret_key: 'changeme'
minio_bin: /usr/local/bin/minio
minio_port: 9000
minio_static_port: 9001
minio_listen_address: 0.0.0.0
minio_volumes:
  - { dev: "/dev/nvme0n1", dir: "/data01", fs: "xfs" }
  - { dev: "/dev/nvme0n2", dir: "/data02", fs: "xfs" }
  - { dev: "/dev/nvme0n3", dir: "/data03", fs: "xfs" }
  - { dev: "/dev/nvme0n4", dir: "/data04", fs: "xfs" }
~~ snip
```

#### 4) Deploy MinIO SNMD
```yaml
$ make snmd r=disable s=firewall
$ make snmd r=create s=dev
$ make snmd r=enable s=ssl
$ make snmd r=setup s=minio
$ make snmd r=setup s=nginx

or
$ make snmd r=install s=all
```

#### 5) Destroy MinIO SNMD
```yaml
$ make snmd r=remove s=minio
$ make snmd r=delete s=dev

or
$ make snmd r=uninstall s=all
```

## For MinIO MNMD ( Multi Nodes Multi Devices )
#### 1) The Architecure of MinIO MNMD 
```
            +-----------------------------------------------------+
            |                      S3 Clients                     |
            +-----------------------------------------------------+
              /              |               \                 \
             v               v                v                 v
       rk9-node01       rk9-node02         rk9-node03         rk9-node04
   +--------------+   +--------------+   +--------------+   +--------------+
   | MinIO Node 1 |   | MinIO Node 2 |   | MinIO Node 3 |   | MinIO Node 4 |
   | /data0{1..4} |<->| /data0{1..4} |<->| /data0{1..4} |<->| /data0{1..4} |
   +--------------|   +--------------+   +--------------+   +--------------+
```

#### 2) Configure Inventory for MinIO MNMD
```yaml
$ vi ansible-hosts-rk9-mnmd

[all:vars]
ssh_key_filename="id_rsa"
remote_machine_username="jomoon"
remote_machine_password="changeme"

[control]
rk9-node01 ansible_ssh_host=192.168.2.171

[workers]
rk9-node01 ansible_ssh_host=192.168.2.171
rk9-node02 ansible_ssh_host=192.168.2.172
rk9-node03 ansible_ssh_host=192.168.2.173
rk9-node04 ansible_ssh_host=192.168.2.174
```

#### 3) Configure Variables
```yaml
$ vi roles/mnmd/defaults/main.yml
---
minio_download: false
~~ snip
minio_access_key: 'admin'
minio_secret_key: 'changeme'
minio_bin: /usr/local/bin/minio
minio_port: 9000
minio_static_port: 9001
minio_listen_address: 0.0.0.0
minio_volumes:
  - { dev: "/dev/nvme0n1", dir: "/data01", fs: "xfs" }
  - { dev: "/dev/nvme0n2", dir: "/data02", fs: "xfs" }
  - { dev: "/dev/nvme0n3", dir: "/data03", fs: "xfs" }
  - { dev: "/dev/nvme0n4", dir: "/data04", fs: "xfs" }
~~ snip

$ vi roles/mnmd/vars/main.yml
---
_certgen:
  download_url: https://github.com/minio/certgen/releases/download
  major_version: 1
  minor_version: 3
  patch_version: 0
  os: linux
  arch: amd64
~~ snip
```

#### 4) Deploy MinIO MNMD
```yaml
$ make mnmd r=disable s=firewall
$ make mnmd r=create s=dev
$ make mnmd r=download s=certgen
$ make mnmd r=enable s=ssl
$ make mnmd r=setup s=minio
$ make mnmd r=setup s=nginx

or
$ make mnmd r=install s=all
```

#### 5) Destroy MinIO MNMD
```yaml
$ make mnmd r=remove s=minio
$ make mnmd r=delete s=dev

or
$ make mnmd r=uninstall s=all
```

## For HAProxy and Keepalived for Distributed MinIO MNMD ( Multi Nodes Multi Devices )
#### 1) The Architecure of HAProxy and Keepalived for MinIO MNMD

```
                   +----------------------+
                   |    S3 Client / User  |
                   +----------------------+
                          /
                         /
                        v (VIP) - https://minio-console.jtest.pivotal.io
           +----------------------+    +------------------------+
   Active  | Keepalived + HAProxy |<-->|  Keepalived + HAProxy  |  Standby
           +----------------------+    +------------------------+
                        |                      |
            +-------------------------------------------+
            |          Load Balanced Traffic            |
            +-------------------------------------------+
               /           |           |              \
              v            v           v               v
     +------------+  +------------+  +------------+  +------------+
     | MinIO Node |  | MinIO Node |  | MinIO Node |  | MinIO Node |
     |  rk9-node1 |  |  rk9-node2 |  |  rk9-node3 |  |  rk9-node4 |
     +------------+  +------------+  +------------+  +------------+
     |/data0{1..4}|  |/data0{1..4}|  |/data0{1..4}|  |/data0{1..4}|
     +------------+  +------------+  +------------+  +------------+

     <---> All nodes form a single MinIO cluster in distributed MNMD mode
```

#### 2) Configure Inventory for HAProxy and Keepalived
```yaml
$ vi ansible-hosts-rk9-haproxy

[all:vars]
ssh_key_filename="id_rsa"
remote_machine_username="jomoon"
remote_machine_password="changeme"

[workers]
rk9-node01 ansible_ssh_host=192.168.1.171
rk9-node02 ansible_ssh_host=192.168.1.172
rk9-node03 ansible_ssh_host=192.168.1.173
rk9-node04 ansible_ssh_host=192.168.1.174

[lb]
rk9-node05  ansible_ssh_host=192.168.1.175  keepalived_role="master"
rk9-node06  ansible_ssh_host=192.168.1.176  keepalived_role="slave"
```

#### 3) Configure Variables for HAProxy and Keepalived
```yaml
$ vi roles/haproxy/vars/main.yml
---
_haproxy:
  cluster_name: minioclu01
  minio_user: minio
  minio_group: minio
  minio_wrapping_port: 5432
  balance_algorithm: roundrobin
  global_max_connections: 4096
  defaults_max_connections: 2000
  user: haproxy
  group: haproxy
  frontend_port: 9000
  stats_port: 8182
  stats_user: haadmin
  stats_pass: changeme


# Variables for Role Keepalived
_keepalived:
  auth_pass: "changeme"
  router_id: "52"
  shared_iface: "{{ netdev1 }}"
  shared_ips:
    - { fe: "minio-console" , ipaddr: "192.168.1.179/24" }
    - { fe: "minio-service" , ipaddr: "192.168.1.180/24" }
  check_process: "haproxy"
  priority: "100"
  backup_priority: "50"
  check_script_name: "check_script"
  unicast_mode: False
  unicast_source: "10.0.0.1"
  unicast_peers:
    - "10.0.0.2"
  email: False                         # Setting an email address will install, start and enable postfix
  notification_script: False           # Execute a custom script when state changes - NOT compatible with email notification
  notification_command_backup: False   # Execute a command when state changes to backup
  notification_command_master: False   # Execute a command when state changes to master
  notification_command_fault:  False   # Execute a command when state changes to fault
~~ snip
```

#### 4) Deploy HAProxy and Keepalived for MinIO MNMD Service
```yaml
$ make haproxy r=disable s=sec
$ make haproxy r=setup   s=ha
$ make haproxy r=setup   s=lb

or
$ make mnmd r=install s=all
```

#### 5) Destroy HAProxy and Keepalived for MinIO MNMD Service
```yaml
$ make haproxy r=remove s=lb
$ make haproxy r=delete s=ha
$ make haproxy r=enable s=sec

or
$ make haproxy r=uninstall s=all
```

## For Distributed MinIO with DirectPV on Kubernetes
#### 1) The Architecure o DirectPV on Kubernetes
<p align="center">
<img src="https://github.com/rokmc756/Kubernetes/blob/main/roles/minio/images/directpv-architecture.svg" width="80%" height="80%">
</p>

#### 2) The Architecure of Distributed MinIO and DirectPV on Kubernetes
<p align="center">
<img src="https://github.com/rokmc756/MinIO/blob/main/roles/minio/images/minio-directpv-architecture.web" width="80%" height="80%">
</p>


#### 2) Configure Variables for DirectPV
```yaml
$ cd Kubernetes
$ vi roles/minio/var/main.yml
---
_krew:
  base_path: "/root"
  download_url: "https://github.com/kubernetes-sigs/krew/releases/latest/download"
  major_version: 0
  minor_version: 4
  patch_version: 5

_directpv:
  base_path: "/root"
  download_url: "https://github.com/minio/directpv/releases/download"
  major_version: 4
  minor_version: 1
  patch_version: 5
~~ snip
```

#### 3) Deploy Distributed MinIO With DirectPV on Kubernetes
```yaml
$ make minio r=install s=directpv
$ make minio r=install s=all
```

#### 4) Distributed Distributed MinIO With DirectPV on Kubernetes
```yaml
$ make minio r=uninstall s=all
$ make minio r=uninstall s=directpv
```

## Planning
- [X] Need to Check Configuration URL Redirect for HAProxy

### References
- https://apps.truenas.com/resources/minio-enterprise-mnmd/
- https://mahendrapalla.hashnode.dev/how-to-set-up-a-multi-node-multi-drive-mnmd-minio-cluster-production-ready
- https://medium.com/@johanesmistrialdo/simple-multinode-multidrive-minio-deployment-f23e09906db1

