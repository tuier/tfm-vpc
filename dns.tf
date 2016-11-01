resource "aws_route53_record" "bastion" {
  #count = "${length(aws_network_interface.bastion.*.private_ips)}"
  count = "${var.azs_count}"

  name           = "bastion-${var.cluster_name}"
  zone_id        = "${var.route_zone_id}"
  type           = "A"
  set_identifier = "${count.index}"

  weighted_routing_policy {
    weight = "${count.index}"
  }

  records         = ["${element(aws_eip.bastion.*.public_ip,count.index)}"]
  ttl             = 60
  health_check_id = "${element(aws_route53_health_check.bastion_check.*.id,count.index)}"
}

resource "aws_route53_health_check" "bastion_check" {
  count = "${var.azs_count}"

  #count = "${length(aws_route53_record.bastion.*.)}"
  ip_address        = "${element(aws_eip.bastion.*.public_ip,count.index)}"
  port              = 22
  type              = "TCP"
  failure_threshold = "2"
  request_interval  = "10"

  tags {
    Name    = "${var.cluster_name}_bastion-check"
    cluster = "${var.cluster_name}"
    product = "${var.tag_product}"
    purpose = "${var.tag_purpose}"
    builder = "terraform"
  }

  lifecycle {
    create_before_destroy = true
  }
}
