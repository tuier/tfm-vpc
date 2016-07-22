resource "aws_security_group" "allow_bastion_ingress" {
  name        = "${var.cluster_name}_allow-bastion-ingress"
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
    Name    = "${var.cluster_name}_allow-bastion-ingress"
    cluster = "${var.cluster_name}"
    product = "${var.tag_product}"
    purpose = "${var.tag_purpose}"
    builder = "terraform"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "bastion" {
  name        = "${var.cluster_name}_bastion"
  description = "Allow all inbound traffic"
  vpc_id      = "${aws_vpc.main.id}"

  tags {
    Name    = "${var.cluster_name}_bastion"
    cluster = "${var.cluster_name}"
    product = "${var.tag_product}"
    purpose = "${var.tag_purpose}"
    builder = "terraform"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "bastion" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = "${aws_security_group.bastion.id}"

  security_group_id = "${aws_security_group.bastion.id}"
}
