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
}

resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.main.id}"

  tags {
    Name    = "${var.cluster_name}"
    cluster = "${var.cluster_name}"
    product = "${var.tag_product}"
    purpose = "${var.tag_purpose}"
    builder = "terraform"
  }
}

# public (front) network 

resource "aws_subnet" "front" {
  count = 3

  #count = "${length(split(",", lookup(var.azs_name, var.region)))}"

  vpc_id                  = "${aws_vpc.main.id}"
  cidr_block              = "10.${var.network_number}.${count.index}.0/24"
  availability_zone       = "${var.region}${element(split(",", lookup(var.azs_name, var.region)), count.index)}"
  map_public_ip_on_launch = true
  tags {
    Name    = "front-${var.cluster_name}-${var.region}${element(split(",", lookup(var.azs_name, var.region)), count.index)}"
    cluster = "${var.cluster_name}"
    product = "${var.tag_product}"
    purpose = "${var.tag_purpose}"
    builder = "terraform"
  }
}

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.default.id}"
  }

  tags {
    Name    = "public-${var.cluster_name}"
    cluster = "${var.cluster_name}"
    product = "${var.tag_product}"
    purpose = "${var.tag_purpose}"
    builder = "terraform"
  }
}

resource "aws_route_table_association" "front" {
  count = 3
   
  # count          = "${length(aws_subnet.front.*.id)}"
  subnet_id      = "${element(aws_subnet.front.*.id,count.index)}"
  route_table_id = "${aws_route_table.public.id}"
}

# NAT
resource "aws_eip" "gw_ip" {
  count = 3
   
  # count = "${length(aws_subnet.front.*.id)}"
  vpc   = true
}

resource "aws_nat_gateway" "gw" {
  count = 3
   
  # count = "${length(aws_eip.gw_ip.*.id)}"

  allocation_id = "${element(aws_eip.gw_ip.*.id, count.index)}"
  subnet_id     = "${element(aws_subnet.front.*.id, count.index)}"
}

# private (back) network 

resource "aws_subnet" "back" {
  count = 3

  #count = "${length(compact(split(",",lookup(var.azs_name, var.region))))}"
  vpc_id            = "${aws_vpc.main.id}"
  cidr_block        = "10.${var.network_number}.1${count.index}.0/24"
  availability_zone = "${var.region}${element(split(",",lookup(var.azs_name, var.region)), count.index)}"

  tags {
    Name    = "back-${var.cluster_name}-${var.region}${element(split(",",lookup(var.azs_name, var.region)), count.index)}"
    cluster = "${var.cluster_name}"
    product = "${var.tag_product}"
    purpose = "${var.tag_purpose}"
    builder = "terraform"
  }
}

resource "aws_route_table" "private" {
  count = 3
   
  # count  = "${length(aws_subnet.back.*.id)}"
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = "${element(aws_nat_gateway.gw.*.id, count.index)}"
  }

  tags {
    Name    = "private-${count.index}-${var.cluster_name}"
    cluster = "${var.cluster_name}"
    product = "${var.tag_product}"
    purpose = "${var.tag_purpose}"
    builder = "terraform"
  }
}

resource "aws_route_table_association" "back" {
  count = 3
   
  # count          = "${length(aws_subnet.back.*.id)}"
  subnet_id      = "${element(aws_subnet.back.*.id,count.index)}"
  route_table_id = "${element(aws_route_table.private.*.id,count.index)}"
}

# s3 endpoint
resource "aws_vpc_endpoint" "private-s3" {
  vpc_id          = "${aws_vpc.main.id}"
  service_name    = "com.amazonaws.${var.region}.s3"
  route_table_ids = ["${aws_route_table.private.*.id}", "${aws_route_table.public.id}"]
}

# bastion configuration

resource "aws_security_group" "allow_bastion" {
  description = "Allow all inbound traffic"
  vpc_id      = "${aws_vpc.main.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name    = "allow-bastion"
    cluster = "${var.cluster_name}"
    product = "${var.tag_product}"
    purpose = "${var.tag_purpose}"
    builder = "terraform"
  }
}

resource "aws_autoscaling_group" "bastion" {
  name             = "bastion-${var.cluster_name}"
  max_size         = 1
  min_size         = 1
  desired_capacity = 1

  health_check_grace_period = 10
  health_check_type         = "EC2"
  force_delete              = true
  launch_configuration      = "${aws_launch_configuration.bastion.name}"
  vpc_zone_identifier       = ["${aws_subnet.front.*.id}"]

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = "bastion-${var.cluster_name}"
    propagate_at_launch = true
  }

  tag {
    key                 = "builder"
    value               = "terraform"
    propagate_at_launch = true
  }

  tag {
    key                 = "cluster"
    value               = "${var.cluster_name}"
    propagate_at_launch = true
  }

  tag {
    key                 = "product"
    value               = "${var.tag_product}"
    propagate_at_launch = true
  }

  tag {
    key                 = "purpose"
    value               = "${var.tag_purpose}"
    propagate_at_launch = true
  }
}

resource "aws_iam_role" "bastion_role" {
  name = "bastion_role_${var.cluster_name}"

  assume_role_policy = <<EOF
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Action": "sts:AssumeRole",
			"Principal": {
				"Service": "ec2.amazonaws.com"
			},
			"Effect": "Allow",
			"Sid": ""
		}
	]
}
EOF
}

resource "aws_iam_instance_profile" "bastion_profile" {
  name  = "bastion_profile_${var.cluster_name}"
  roles = ["${aws_iam_role.bastion_role.name}"]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy" "bastion_policy" {
  name = "bastion_policy_${var.cluster_name}"
  role = "${aws_iam_role.bastion_role.id}"

  policy = <<EOF
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Effect": "Allow",
			"Action": [
				"route53:ChangeResourceRecordSets"
			],
			"Resource": "*"
		}
	]
}
EOF
}

resource "aws_route53_record" "bastion" {
  name    = "bastion-${var.cluster_name}"
  zone_id = "${var.zone_id}"
  type    = "A"
  records = ["10.0.0.0"]
  ttl     = 60

  lifecycle {
    # this will be updated with the user_data of the launch configuration
    # https://github.com/hashicorp/terraform/issues/5627
    ignore_changes = ["records"]
  }
}

resource "aws_launch_configuration" "bastion" {
  name_prefix                 = "bastion-${var.cluster_name}-"
  image_id                    = "${lookup(var.ami_bastion, var.region)}"
  instance_type               = "${var.instance_type_bastion}"
  key_name                    = "${var.aws_key_name}"
  associate_public_ip_address = true
  iam_instance_profile        = "${aws_iam_instance_profile.bastion_profile.name}"
  security_groups             = ["${aws_security_group.allow_bastion.id}", "${aws_vpc.main.default_security_group_id}"]

  user_data = "${template_file.launch_bastion.rendered}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "template_file" "launch_bastion" {
  vars {
    region          = "${var.region}"
    route53_zone_id = "${var.zone_id}"
    fqdn            = "${var.fqdn}"
  }

  template = "${file("${path.module}/bastion_user_data.tpl")}"

  lifecycle {
    create_before_destroy = true
  }
}
