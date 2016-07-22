# public network

resource "aws_subnet" "public" {
  count = "${var.azs_count}"

  #count = "${length(split(",", lookup(var.azs_name, var.region)))}"

  vpc_id            = "${aws_vpc.main.id}"
  cidr_block        = "10.${var.network_number}.${count.index}.0/24"
  availability_zone = "${var.region}${element(split(",", lookup(var.azs_name, var.region)), count.index)}"
  tags {
    Name    = "${var.cluster_name}_public-${element(split(",", lookup(var.azs_name, var.region)), count.index)}"
    cluster = "${var.cluster_name}"
    product = "${var.tag_product}"
    purpose = "${var.tag_purpose}"
    builder = "terraform"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.default.id}"
  }

  tags {
    Name    = "${var.cluster_name}_public"
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

resource "aws_route_table_association" "public" {
  count = "${var.azs_count}"

  # count          = "${length(aws_subnet.public.*.id)}"
  subnet_id      = "${element(aws_subnet.public.*.id,count.index)}"
  route_table_id = "${aws_route_table.public.id}"

  lifecycle {
    create_before_destroy = true
  }
}
