#!/bin/bash
#

for ln in $(cat /home/jomoon/.ssh/known_hosts | grep -n 192.168.0.231 | cut -d : -f 1)
do
    echo $ln
    sed -ie "$ln"d /home/jomoon/.ssh/known_hosts
done

esxi_host_addr="192.168.0.231"
esxi_host_user="root"
esxi_host_pass="Changeme34#$"

# vim-cmd vmsvc/power.getstate <vmid>
sshpass -p "$esxi_host_pass" ssh -o StrictHostKeyChecking=no $esxi_host_user@$esxi_host_addr "vim-cmd vmsvc/getallvms | awk '{print \$2}'"

