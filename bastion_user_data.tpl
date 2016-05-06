#!/bin/bash -v

EC2_URL=https://ec2.${region}.amazonaws.com

# set fqdn pointing to instance ip
if [[ -n "${route53_zone_id}" && -n "${fqdn}" ]]; then
	MYMAC=$(wget http://169.254.169.254/latest/meta-data/network/interfaces/macs/ -O - -q)
	MYIP=$(wget http://169.254.169.254/latest/meta-data/network/interfaces/macs/$MYMAC/ipv4-associations -O - -q)

	cat << EOF > /tmp/route53-change.json
{
	"Comment": "Updating Bastion Host Record",
	"Changes": [
		{
			"Action": "UPSERT",
			"ResourceRecordSet": {
				"Name": "bastion-${fqdn}",
				"Type": "A",
				"TTL": 60,
				"ResourceRecords": [
					{
						"Value": "$MYIP"
					}
				]
			}
		}
	]
}
EOF
	aws route53 change-resource-record-sets --hosted-zone-id "${route53_zone_id}" --change-batch file:///tmp/route53-change.json
	rm -rf /tmp/route53-change.json
fi
