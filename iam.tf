resource "aws_iam_role" "bastion_role" {
  name = "${var.cluster_name}_bastion_role"

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

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_instance_profile" "bastion_profile" {
  name  = "${var.cluster_name}_bastion_profile"
  roles = ["${aws_iam_role.bastion_role.name}"]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy" "bastion_policy" {
  name = "${var.cluster_name}_bastion_policy"
  role = "${aws_iam_role.bastion_role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": {
	"Effect": "Allow",
	"Action": [
	  "ec2:AttachNetworkInterface",
	  "ec2:DescribeNetworkInterfaces",
	  "ec2:DetachNetworkInterface"
	],
	"Resource": [
	  "*"
	]
  }
}
EOF

  lifecycle {
    create_before_destroy = true
  }
}
