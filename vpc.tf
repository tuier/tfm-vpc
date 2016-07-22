provider "aws" {
  region = "${var.region}"
}

resource "aws_vpc" "main" {
  cidr_block           = "10.${var.network_number}.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags {
    Name    = "${var.cluster_name}"
    cluster = "${var.cluster_name}"
    product = "${var.tag_product}"
    purpose = "${var.tag_purpose}"
    builder = "terraform"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_dhcp_options_association" "dns_resolver" {
  vpc_id          = "${aws_vpc.main.id}"
  dhcp_options_id = "${aws_vpc_dhcp_options.search.id}"
}

resource "aws_vpc_dhcp_options" "search" {
  domain_name         = "${var.fqdn} ${var.region}.compute.internal"
  domain_name_servers = ["AmazonProvidedDNS"]

  tags {
    Name    = "${var.cluster_name}_default_search"
    cluster = "${var.cluster_name}"
    product = "${var.tag_product}"
    purpose = "${var.tag_purpose}"
  }
}

resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.main.id}"

  tags {
    Name    = "${var.cluster_name}_ig"
    cluster = "${var.cluster_name}"
    product = "${var.tag_product}"
    purpose = "${var.tag_purpose}"
    builder = "terraform"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# s3 endpoint
resource "aws_vpc_endpoint" "private-s3" {
  vpc_id          = "${aws_vpc.main.id}"
  service_name    = "com.amazonaws.${var.region}.s3"
  route_table_ids = ["${aws_route_table.private.*.id}", "${aws_route_table.public.id}"]

  lifecycle {
    create_before_destroy = true
  }
}
