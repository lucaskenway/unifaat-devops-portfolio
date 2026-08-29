# =============================================================
# EC2 — AMI, Key Pair e Instância
# =============================================================

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_key_pair" "main" {
  key_name   = var.key_name
  public_key = file(pathexpand(var.public_key_path))

  tags = merge(local.common_tags, { Name = "${local.prefix}-key" })
}

resource "aws_instance" "api" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.api.id]
  key_name               = aws_key_pair.main.key_name
  iam_instance_profile   = data.aws_iam_instance_profile.lab.name
  user_data              = file("${path.module}/user_data.sh")

  root_block_device {
    volume_size = 8
    volume_type = "gp2"
  }

  tags = merge(local.common_tags, { Name = "${local.prefix}-api" })
}
