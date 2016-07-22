# bastion configuration

resource "aws_eip" "bastion" {
  count = "${var.azs_count}"

  # count = "${length(aws_network_interface.bastion.*.id)}"
  network_interface = "${element(aws_network_interface.bastion.*.id,count.index)}"
  vpc               = true

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_network_interface" "bastion" {
  count = "${var.azs_count}"

  # count          = "${length(aws_subnet.public.*.id)}"
  subnet_id       = "${element(aws_subnet.public.*.id,count.index)}"
  description     = "${var.cluster_name}_bastion endpoint for ${element(aws_subnet.public.*.availability_zone,count.index)}"
  security_groups = ["${aws_security_group.allow_bastion_ingress.id}"]

  tags {
    Name    = "${var.cluster_name}_eni-bastion-${element(aws_subnet.public.*.id,count.index)}"
    cluster = "${var.cluster_name}"
    product = "${var.tag_product}"
    purpose = "${var.tag_purpose}"
    builder = "terraform"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "bastion" {
  name             = "${var.cluster_name}_bastion"
  max_size         = 1
  min_size         = 1
  desired_capacity = 1

  health_check_grace_period = 120
  health_check_type         = "EC2"
  force_delete              = true
  launch_configuration      = "${aws_launch_configuration.bastion.name}"
  vpc_zone_identifier       = ["${aws_subnet.public.*.id}"]

  tag {
    key                 = "Name"
    value               = "${var.cluster_name}_bastion"
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

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_launch_configuration" "bastion" {
  name_prefix                 = "${var.cluster_name}_bastion-"
  image_id                    = "${lookup(var.ami_bastion, var.region)}"
  instance_type               = "${var.instance_type_bastion}"
  key_name                    = "${var.aws_key_name}"
  associate_public_ip_address = true
  iam_instance_profile        = "${aws_iam_instance_profile.bastion_profile.name}"
  security_groups             = ["${aws_security_group.allow_bastion_ingress.id}", "${aws_security_group.bastion.id}"]

  user_data = "${template_file.launch_bastion.rendered}\n${var.user_data}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "template_file" "launch_bastion" {
  vars {
    region   = "${var.region}"
    enis_map = "${join(" ",template_file.enis_map.*.rendered)}"
  }

  template = "${file("${path.module}/bastion_user_data.tpl")}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "template_file" "enis_map" {
  # count = "${length(aws_network_interface.bastion.*.id)}"

  count = "${var.azs_count}"

  vars {
    zone = "${replace(element(split(" ", element(aws_network_interface.bastion.*.description,count.index)),3),"${var.region}","")}"
    eni  = "${element(aws_network_interface.bastion.*.id,count.index)}"
  }

  template = "[\"${zone}\"]=\"${eni}\""

  lifecycle {
    create_before_destroy = true
  }
}
