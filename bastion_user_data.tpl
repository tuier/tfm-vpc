#!/bin/bash -v
ZONE=$(wget -qO - http://169.254.169.254/latest/meta-data/placement/availability-zone)
INSTANCE_ID=$$(wget http://169.254.169.254/latest/meta-data/instance-id -O - -q)

declare -A enis_map
enis_map=(${enis_map})
eni=$${enis_map[$${ZONE: -1}]}
/usr/bin/aws ec2 attach-network-interface --network-interface-id $${eni} --instance-id $${INSTANCE_ID} --device-index 1 --region '${region}'
/bin/sleep 60

ec2ifscan
