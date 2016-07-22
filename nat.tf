# NAT
resource "aws_eip" "gw_ip" {
  count = "${var.azs_count}"

  # count = "${length(aws_subnet.public.*.id)}"
  vpc = true

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_nat_gateway" "gw" {
  count = "${var.azs_count}"

  # count = "${length(aws_eip.gw_ip.*.id)}"

  allocation_id = "${element(aws_eip.gw_ip.*.id, count.index)}"
  subnet_id     = "${element(aws_subnet.public.*.id, count.index)}"
  lifecycle {
    create_before_destroy = true
  }
}
