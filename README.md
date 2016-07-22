

# VPC

This terraform module can create a cross zone vpc.

###### Result

This will create a vpc across multiple zone with a couple of subnet, routing 
table, bastion instance, elb and Managed NAT

### Subnet

There will be two level of subnet the public and the private and there will be 
a subnet per level per zone

### route table

one routing table are create one public and one for each subnet in private 
subnets.
the public is linked to the public's subnets and the Internet Gateway, the 
private to the private's subnets and the Managed NAT

### bastion instance and routing

A bastion is launched through an auto scaling group in all public's subnets.
In each subnet an ENI and EIP is created.
When a new Bastion instance is booted a command to change the ENI association
is run to make sure he always have associated with one ENI/EIP.
Some DNS record and healh-check will route to bastion no matter with ENI is 
using.

### NAT

All public's subnet have one Managed NAT gateway and a routing table is create 
for each private's subnet with a route from the subnet to the (AZ) 
corresponding NAT gateway

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
|  | pub   a |   | pub   b |   | pub   c |  |
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
|  | priv  a |   | priv  b |   | priv  c |  |
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


region: the region you want your vpc on
azs_name: the zone you want your vpc on
azs_count: number of zone you want your vpc on, must be not be superior of the 
number of zone available on the region

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

subnets: all subnet id from the private

default_sg:  the default SecurityGroup for the vpc


## Improvement

* need a way to rotate key in the bastion
* Use a dynamic count value for subnet https://github.com/hashicorp/terraform/issues/3888
* Have https://github.com/hashicorp/terraform/issues/5627 fixed to be able to 
ignore external change (bastion) to the dns
