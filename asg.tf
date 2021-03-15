## Generating SSH keys and Keypair (Generating both public & private keys, can automate storing private key somewhere in secret store and can remove from local)
resource "null_resource" "ssh" {
  triggers = {
    public-keyname  = "test.pub"
    private-keyname = "test"
  }
   provisioner "local-exec" {
    when       = destroy
    on_failure = continue
    command = <<EOC
     rm ${self.triggers.public-keyname} ${self.triggers.private-keyname}
   EOC
  }
}

resource "null_resource" "ssh-keygen" {
  depends_on = [
    null_resource.ssh,
  ]

  provisioner "local-exec" {
    command = <<EOC
     echo -e  'y\n' | ssh-keygen -t rsa -b 4096 -m PEM -f ${null_resource.ssh.triggers.private-keyname} -N ''
   EOC
  } 
}

data "local_file" "ssh_key" {
  filename   = null_resource.ssh.triggers.public-keyname
  depends_on = [null_resource.ssh-keygen]
}

resource "aws_key_pair" "keypair" {
  key_name   = null_resource.ssh.triggers.private-keyname
  public_key = data.local_file.ssh_key.content
  depends_on = [null_resource.ssh-keygen,]

  lifecycle {
    ignore_changes = [public_key]
  }
}

# IAM Role
resource "aws_iam_role" "tier" {
  name = "test"
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {"Service": "ec2.amazonaws.com"},
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

# IAM instance profile
resource "aws_iam_instance_profile" "tier" {
  name = "test"
  role = aws_iam_role.tier.name
}

# Security Group
resource "aws_security_group" "custom_sg" {
  name        = "test"
  description = "Allow HTTP inbound connections"
  vpc_id = aws_vpc.test.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

data "template_file" "user_data" {
template = file("userdata.sh")
}

# Launch template
resource "aws_launch_template" "launch_tier" {
  name_prefix   = "test"
  image_id      = "ami-096fda3c22c1c990a"         # setting test image id, need to replace with required image id
  instance_type = "t3.medium"

  iam_instance_profile {
    name    = aws_iam_instance_profile.tier.name
  }

  key_name  = aws_key_pair.keypair.key_name  
  user_data = base64encode(data.template_file.user_data.rendered)
  
  #vpc_security_group_ids = [aws_security_group.custom_sg.id]
  
  monitoring {
    enabled = true
  }
  
  network_interfaces {
    associate_public_ip_address = true
    security_groups = [aws_security_group.custom_sg.id]
  }

  dynamic "block_device_mappings" {
    for_each = [for volume in var.block_device_mappings: {
      device_name = lookup(volume, "device_name" )
      delete_on_termination = lookup(volume, "delete_on_termination")
      encrypted = lookup(volume, "encrypted")
      volume_size = lookup(volume, "volume_size")
      volume_type = lookup(volume, "volume_type")
    }]
    content {
      device_name = block_device_mappings.value.device_name
      ebs {
        delete_on_termination = block_device_mappings.value.delete_on_termination
        encrypted = block_device_mappings.value.encrypted
        volume_size = block_device_mappings.value.volume_size
        volume_type = block_device_mappings.value.volume_type
      }
    }
   }

  lifecycle {
    create_before_destroy = true
  }
}

# AutoScaling Group
resource "aws_autoscaling_group" "tier" {
  name = "test"

  launch_template {
    id      = aws_launch_template.launch_tier.id
    version = "$Latest"
  }

  max_size                  = 5
  min_size                  = 3
  desired_capacity          = 3
  health_check_grace_period = 900
  health_check_type         = "EC2"

  target_group_arns = [aws_alb_target_group.tier_target_group.arn]

  vpc_zone_identifier = [
    aws_subnet.test_subnet_east_1a.id,
    aws_subnet.test_subnet_east_1b.id
  ]
  suspended_processes = []

  tag {
    key                 = "Name"
    value               = "web"
    propagate_at_launch = true
  }
  
  tag {
    key                 = "Environment"
    value               = "Test"
    propagate_at_launch = true
  }

  tag {
    key                 = "ManagedBy"
    value               = "terraform"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}