output "vpc_id" {
  value = "${aws_vpc.main.id}"
}

output "subnets" {
  value = "${join(",",aws_subnet.back.*.id)}"
}

output "default_sg" {
  value = "${aws_vpc.main.default_security_group_id}"
}
