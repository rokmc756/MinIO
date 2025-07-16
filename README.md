## What is MinIO Ansible Playbook?
It is ansible playbook to deploy Distributed MinIO SNMD ( Single Node Multi Devices ) and MNMD ( Multi Nodes Multi Devices ) with HAProxy and Keepalived on Baremetal, Virtual Machines and Cloud Infrastructure.
The main purpose of this project is actually very simple. Because there are many jobs to install different kind of MinIO versions and reproduce issues & test features as a support
engineer. I just want to spend less time for it.

If you are working with MinIO such as Developer, Administrator, Field Engineer or Storage Administrator you could also utilize it very conviently as saving time.

<p align="center">
<img src="https://github.com/rokmc756/MinIO/blob/main/roles/mnmd/images/minio-architecture.webp" width="90%" height="90%">
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

## Download All MinIO Softwares
```yaml
$ vi download-vars.yml
---
_mc:
  release_date: 2025-05-21T01-59-54Z
  patch_version: 1
  download_url: https://dl.minio.io/client/mc/release/linux-amd64
  download_archive_url: https://dl.minio.io/client/mc/release/linux-amd64/archive

~~ snip

_minio:
  release_date: 20250422221226.0.0  # Last Release to Support Full Feature which is Not Community Version
  bin_release_date: 2025-04-22T22-12-26Z
  patch_version: 1
  download_url: https://dl.minio.io/server/minio/release/linux-amd64/archive
  arch_type: x86_64
  bin_type: rpm # bin
~~ snip


$ make download
```

## Configure Global Variables
```yaml
$ vi group_vars/all.yml
---
_minio:
  base_path: "/home/minio"
  cluster_name: jack-kr-minio
  domain: "jtest.pivotal.io"
  download: false
  bin_type: rpm  # bin
  release_date: 20250422221226.0.0        # Last Release to Support Full Feature which License is not Required
  bin_release_date: 2025-04-22T22-12-26Z
  patch_version: 1
  download_url: https://dl.minio.io/server/minio/release/linux-amd64/archive
  server_url: https://dl.minio.io/server/minio/release/linux-amd64/minio
  os_version: el9
  arch_type: x86_64
  access_key: minioadmin
  secret_key: changeme
  server_checksum:
  user: minio
  group: minio
  service: "minio"
  user_home: /home/minio
  config: "/home/minio/.minio/config.json"
  bin: /usr/local/bin/minio
  bin_dir: /usr/local/bin
  listen_address: 0.0.0.0
  api_port: 9000
  console_port: 9001
  http_port: 80
  https_port: 443
  ec:
    stripe_size: 16
    parity: 4
  volumes:
    - { dev: "/dev/nvme0n1", dir: "/data01", fs: "xfs" }
    - { dev: "/dev/nvme0n2", dir: "/data02", fs: "xfs" }
    - { dev: "/dev/nvme0n3", dir: "/data03", fs: "xfs" }
    - { dev: "/dev/nvme0n4", dir: "/data04", fs: "xfs" }
~~ snip

_certgen:
  download_url: https://github.com/minio/certgen/releases/download
  major_version: 1
  minor_version: 3
  patch_version: 0
  os: linux
  arch: amd64
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

#### 3) Deploy MinIO SNMD
```yaml
$ make snmd r=disable s=firewall
$ make snmd r=create s=dev
$ make snmd r=enable s=ssl
$ make snmd r=setup s=minio
$ make snmd r=setup s=nginx

or
$ make snmd r=install s=all
```

#### 4) Destroy MinIO SNMD
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

#### 3) Deploy MinIO MNMD
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

#### 4) Destroy MinIO MNMD
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
  global_max_connections: 4096
  defaults_max_connections: 2000
  user: haproxy
  group: haproxy
  stats_port: 8182
  stats_user: haadmin
  stats_pass: changeme
  minio:
    user: minio
    group: minio
    password: changeme
    api:
      frontend_port: 9000
      backend_port: 9000
      balance: leastconn
    console:
      frontend_port: 9001
      backend_port: 9001
      balance: leastconn


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
$ make lb r=disable s=sec
$ make lb r=setup   s=ha
$ make lb r=setup   s=haproxy

or
$ make lb r=install s=all

# Test MinIO API Port Load Balanced by HAProxy
$ mc alias set myminio https://minio-api.jtest.pivotal.io:9000 minioadmin changeme --insecure
```

#### 5) Destroy HAProxy and Keepalived for MinIO MNMD Service
```yaml
$ make lb r=remove s=haproxy
$ make lb r=delete s=ha
$ make lb r=enable s=sec

or
$ make lb r=uninstall s=all
```

#### 6) Replace NGINX Reverse Proxy Load Balancer and Keepalived for MinIO MNMD Service
```yaml
$ make lb r=uninstall s=haproxy
$ make lb r=disable s=sec
$ make lb r=setup   s=nginx

# Test MinIO API Port Load Balanced by NGINX Reverse Proxy
$ mc alias set myminio http://minio-api.jtest.pivotal.io minioadmin changeme --insecure
```

#### 7) Destroy NGINX Reverse Proxy Load Balancer and Keepalived for MinIO MNMD Service
```yaml
$ make lb r=remove s=nginx
$ make lb r=delete s=ha
$ make lb r=enable s=sec
```

## Install MinIO Client and Performance Benchmark Tools
```yaml
$ make client r=install s=mc
$ make client r=install s=mcli
$ make client r=install s=warp

or
$ make client r=install s=all
```

## For Distributed MinIO with DirectPV on Kubernetes
#### 1) The Architecure o DirectPV on Kubernetes
<p align="center">
<img src="https://raw.githubusercontent.com/rokmc756/MinIO/refs/heads/main/roles/mnmd/images/directpv-architecture.svg" width="90%" height="90%">
</p>

#### 2) The Architecure of Distributed MinIO and DirectPV on Kubernetes
<p align="center">
<img src="https://raw.githubusercontent.com/rokmc756/MinIO/refs/heads/main/roles/mnmd/images/minio-directpv-architecture.webp" width="90%" height="90%">
</p>


#### 3) Configure Variables for DirectPV
```yaml
$ git clone https://github.com/rokmc756/Kubernetes
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

#### 4) Deploy Distributed MinIO With DirectPV on Kubernetes
```yaml
$ git clone https://github.com/rokmc756/Kubernetes
$ cd Kubernetes
$ make minio r=install s=directpv
$ make minio r=install s=all
```

#### 5) Destroy Distributed MinIO With DirectPV on Kubernetes
```yaml
$ git clone https://github.com/rokmc756/Kubernetes
$ cd Kubernetes
$ make minio r=uninstall s=all
$ make minio r=uninstall s=directpv
```

## Planning
- [O] Need to Check Configuration URL Redirect for HAProxy : Check haproxy.cfg
- [O] Configure Combination of NGINX and MinIO ( http+http, https+http, https+https )
- [ ] Failed to combination of Non-SSL NGINX and SSL SNMD and MNMD MinIO ( http+https )


### References
- https://apps.truenas.com/resources/minio-enterprise-mnmd/
- https://mahendrapalla.hashnode.dev/how-to-set-up-a-multi-node-multi-drive-mnmd-minio-cluster-production-ready
- https://medium.com/@johanesmistrialdo/simple-multinode-multidrive-minio-deployment-f23e09906db1


<div class="mx-auto rounded-lg mb-10 max-w-3xl w-full">
    <div class="video-loader relative" data-video-url="/resources/media/active-active-replication.mp4" data-video-type="raw">
        <img width="672" height="378" class="rounded-lg shadow-poster w-full cursor-pointer"
        src="https://min.io/products/active-data-replication-for-object-storage/resources/media/posters/aistor/cover-5.png" alt="Replication" loading="lazy">
        <div class="text-theme-red m-5 sm:m-8 pl-1 leading-none text-xs sm:text-md font-heading uppercase font-medium absolute left-0 bottom-0 tracking-widest">Active-Active Replication</div>
    </div>
</div>

