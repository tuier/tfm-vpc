output "id" {
  value = "${aws_vpc.main.id}"
}

output "subnets_private" {
  value = "${join(",",aws_subnet.private.*.id)}"
}

output "subnets_public" {
  value = "${join(",",aws_subnet.public.*.id)}"
}

output "azs" {
  value = "${var.region}${replace(lookup(var.azs_name, var.region),",",",${var.region}")}"
}

output "nat_ip" {
  value = "${join(",",aws_nat_gateway.gw.*.public_ip)}"
}

output "sg_bastion" {
  value = "${aws_security_group.bastion.id}"
}

output "sg_default" {
  value = "${aws_vpc.main.default_security_group_id}"
}

output "cidr_block" {
  value = "${aws_vpc.main.cidr_block}"
}
