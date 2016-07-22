# private network

resource "aws_subnet" "private" {
  count = "${var.azs_count}"

  #count = "${length(compact(split(",",lookup(var.azs_name, var.region))))}"
  vpc_id            = "${aws_vpc.main.id}"
  cidr_block        = "10.${var.network_number}.1${count.index}.0/24"
  availability_zone = "${var.region}${element(split(",",lookup(var.azs_name, var.region)), count.index)}"

  tags {
    Name    = "${var.cluster_name}_private-${element(split(",",lookup(var.azs_name, var.region)), count.index)}"
    cluster = "${var.cluster_name}"
    product = "${var.tag_product}"
    purpose = "${var.tag_purpose}"
    builder = "terraform"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route_table" "private" {
  count = "${var.azs_count}"

  # count  = "${length(aws_subnet.private.*.id)}"
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = "${element(aws_nat_gateway.gw.*.id, count.index)}"
  }

  tags {
    Name    = "${var.cluster_name}_private-${count.index}"
    cluster = "${var.cluster_name}"
    product = "${var.tag_product}"
    purpose = "${var.tag_purpose}"
    builder = "terraform"
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = ["route"]
  }
}

resource "aws_route_table_association" "private" {
  count = "${var.azs_count}"

  # count          = "${length(aws_subnet.private.*.id)}"
  subnet_id      = "${element(aws_subnet.private.*.id,count.index)}"
  route_table_id = "${element(aws_route_table.private.*.id,count.index)}"

  lifecycle {
    create_before_destroy = true
  }
}
