data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

resource "aws_key_pair" "ansible" {
  key_name   = "ansible"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCZk1SBF6uZwMycfP4t8d0g4tcqRMtKnR4R7noGNavboRpm6iSc4Owqwm4ZCq96YOpAYpSU1fO4IrqvlInAtP5YYd315UHwq0eezkm/S6gvOB6oYI0oMx85Yyi9qPIQux+xmMyzCMwB+Tmc2U1lpmbmTCZMnxc0BwReHuGykyqK8CactKLrmax4ADYzPYZ/LejSQ46uSSK2ifYPYytkvvQnrkQwqBO4tRPqTrvBHIZLwewJ5+OnB3N80bOZW5KJ2kUbsxEZrvhGao5li5ugq/Sa4OWAzMvK8C7LT6Lp4BRSTAvSzQTYEtJwwjBh6OgJgOyV1/cjOMkPNyHHqhjWeQVG8PQ4Rc+1DAMHoSAhYftykiGIKBmxQcgNEsFwK2lsNN4dxVJb7OqTm3lew0q3KS0kQPlGwcJ9I5u2o8zS9Lie72RH2TBrkI26iW4yObsbCvYZae9m34uvWPh8eyp+4MoLzgERkpAmzV1CqUWoGirCmzcslZNJ1WWHRull/w6JuOxAUbO5ekEUPxpuVuRJn6bWTeHMGNy52+NmlySc/sqQv0Bvg607jHUsgg+8WEWzGNoXtoQcFguuHQsDds34f+DIpAYfOPK6KsP7CXwft0aItqzaqlvvzJtIlb4uZo/3XoMiPTLxGBmjBxjYUiPnT1hf+0qTanvh0L3vhpf2y+u/9Q=="
}

resource "aws_instance" "session_manager" {
  ami                    = "${data.aws_ami.ubuntu.id}"
  instance_type          = "t3.small"
  subnet_id              = "${module.vpc.public_subnets[0].id}"
  key_name               = "${aws_key_pair.ansible.key_name}"
  iam_instance_profile   = "${aws_iam_instance_profile.session_manager.name}"
  vpc_security_group_ids = ["${aws_security_group.awx.id}"]

  root_block_device {
    volume_size = "30"
  }

  tags = {
    Name = "AWX"
    type = "awx"
    stage = "${var.stage}"
  }
}

resource "aws_security_group" "awx" {
  name = "AWX"
  description = "Allow inbound SSH"
  vpc_id = "${module.vpc.vpc.id}"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["67.245.242.207/32"]
  }

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["67.245.242.207/32"]
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["67.245.242.207/32"]
  }


  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}
