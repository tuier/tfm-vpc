variable "region" {}

variable "azs_count" {
  default = 3
}

variable "azs_name" {
  default = {
    eu-west-1      = "a,b,c"
    ap-southeast-1 = "a,b"
    ap-southeast-2 = "a,b"
    eu-central-1   = "a,b"
    ap-northeast-1 = "a,b,c"
    us-east-1      = "b,c,d,e"
    sa-east-1      = "a,b,c"
    us-west-1      = "b,c"
    us-west-2      = "a,b,c"
  }
}

variable "network_number" {
  default = "200"
}

# https://aws.amazon.com/amazon-linux-ami/
variable "ami_bastion" {
  default = {
    ap-northeast-1 = "ami-4232172c"
    ap-southeast-1 = "ami-deb176bd"
    ap-southeast-2 = "ami-cad986a9"
    eu-west-1      = "ami-54e03f27"
    sa-east-1      = "ami-7b15ad17"
    us-east-1      = "ami-66b6c60c"
    us-west-1      = "ami-ede78b8d"
    us-west-2      = "ami-31342050"
    eu-central-1   = "ami-8d4a59e1"
  }
}

variable "instance_type_bastion" {
  default = "m3.medium"
}

variable "aws_key_name" {
  default = ""
}

variable "cluster_name" {
  default = "vpc-test"
}

variable "route_zone_id" {
  default     = ""
  description = "dn zone where you want the dn record in, AWS ID of the FLD"
}

variable "fqdn" {
  default     = ""
  description = "domain name that you want the bastion on, should use a subdomain, result bastion-<cluster_name>.<fqdn>"
}

variable "user_data" {
  default     = ""
  description = "extra user data added to the bastion, must be shell"
}

variable "tag_product" {
  default = "devops"
}

variable "tag_purpose" {
  default = "research"
}
