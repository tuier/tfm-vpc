

# VPC

This terraform module can create a cross zone vpc.

###### Result

This will create a vpc across multiple zone with a couple of subnet, routing 
table, bastion instance, elb ans Managed NAT

### Subnet

There will be two level of subnet the front and the back and there will be 
a subnet per type per zone

### route table

two routing table are create one public and one private the public is linked to 
the front subnets and the Gateway
the private to the back subnets and the Managed NAT

### bastion instance and routing

all bastion instance will be launched in an auto scaling group in the from subnets
When a new Bastion instance is spawned a command to change the EIP association
is run to make sure we always have the same IP

### NAT

All front subnet have one Managed NAT gateway and a routing table is create for
 each back subnet with a route from the subnet to the (AZ) corresponding NAT gateway

## Schema for 3 zone

```
---VPC---------------------------------------
|                                           |
|					Gateway                 |
|                                           |
|                      |                    |
|                 ___________               |
|                /           \              |
|               | route table |             |
|               |   public    |             |
|                \___________/              |
|            /        |         \           |
|  .---------.   .---------.   .---------.  |
|  |         |   |         |   |         |  |
|  | subnet  |   | subnet  |   | subnet  |  |
|  | front a |   | front b |   | front c |  |
|  |         |   |         |   |         |  |
|  |  .---.  |   |  .---.  |   |  .---.  |  |
|  |  |NAT|  |   |  |NAT|  |   |  |NAT|  |  |
|  |  '---'  |   |  '---'  |   |  '---'  |  |
|  '----|----'   '----|----'   '----|----'  |
|       |             |             |       |
|   .-------.     .-------.     .-------.   |
|   |private|     |private|     |private|   |
|   |routing|     |routing|     |routing|   |
|   |-table |     |-table |     |-table |   |
|   '-------'     '-------'     '-------'   |
|       |             |             |       |
|  .---------.   .---------.   .---------.  |
|  |         |   |         |   |         |  |
|  | subnet  |   | subnet  |   | subnet  |  |
|  | back  a |   | back  b |   | back  c |  |
|  |         |   |         |   |         |  |
|  |         |   |         |   |         |  |
|  |         |   |         |   |         |  |
|  |         |   |         |   |         |  |
|  '---------'   '---------'   '---------'  |
|                                           |
|                                           |
---------------------------------------------

```


## INPUT

As input you need to specified the following variable:


region: the region you want you vpc on
azs_name: the zone you want your vps on

network_network: a number to determine the network prefix 
(10,<network_number>.0.0/24)

ami_baxtion: the ami you want to use for the bastion instances
instance_type_bastion: type of instance you want for bastion
aws_key_name: the ssh key name that you want to use for the bastion instance

cluster_name: the cluster name, most of resources will be tagged/named with 
that name
fqdn: domain name that you want the bastion on, should use a subdomain, result 
bastion-<cluster_name>.<fqdn>
tags: all tag who should be on every resources
(https://github.com/hashicorp/terraform/issues/1336)



## OUTPUT

vpc_id: id of the vpc newly created

subnets: all subnet id from the private area value

default_sg:  the default SecurityGroup for the vpc


## Improvement

* need a way to rotate key in the bastion
* Use a dynamic count value for subnet https://github.com/hashicorp/terraform/issues/3888
* Have https://github.com/hashicorp/terraform/issues/5627 fixed to be able to 
ignore external change (bastion) to the dns
