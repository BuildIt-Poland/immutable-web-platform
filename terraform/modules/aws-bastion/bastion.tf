resource "aws_key_pair" "bastion_key" {
  key_name   = "${var.cluster_name}-bastion-key"
  public_key = file("${var.ssh_pub_key}")
}

# resource "aws_default_vpc" "default" {}

data "aws_ami" "amazon-linux-2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

# TODO add private key?
resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.amazon-linux-2.id
  key_name                    = aws_key_pair.bastion_key.key_name
  instance_type               = "t2.micro"
  vpc_security_group_ids      = [aws_security_group.bastion-sg.id]
  associate_public_ip_address = true
  subnet_id                   = var.vpc.public_subnets[0]

  tags = merge(
    var.common_tags,
    { Name = "${var.cluster_name}-bastion" }
  )
}

resource "aws_security_group" "bastion-sg" {
  name   = "${var.cluster_name}-bastion-security-group"
  vpc_id = var.vpc.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.common_tags
}

output "public_ip" {
  value = aws_instance.bastion.public_ip
}

output "ssh_key" {
  value = aws_key_pair.bastion_key
}

