root_pass="changeme"

for i in `seq 1 6`
do

    END_IP=$(( 170 + $i ))
    echo $END_IP
    sshpass -p "$root_pass" ssh -o StrictHostKeyChecking=no root@192.168.1.$END_IP "reboot"

done

