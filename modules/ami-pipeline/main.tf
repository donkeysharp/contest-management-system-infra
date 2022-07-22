locals {
  component_arns = [
  ]

  user_data = <<EOF
#!/bin/bash
echo "It worked!" > /opt/worked-ami.txt
  EOF
}

provider "aws" {
  region = var.region
}

resource "aws_s3_bucket" "builder_data" {
  bucket = var.image_builder_bucket_name
  tags = var.tags
}

resource "aws_imagebuilder_image_recipe" "default" {
  name              = var.image_builder_name
  version           = "1.0.0"
  parent_image      = var.image_builder_base_ami_id

  working_directory = "/var/tmp"

  user_data_base64 = base64encode(local.user_data)


  # TODO: enable encryption in both
  block_device_mapping {
    device_name = "/dev/xvda"

    ebs {
      delete_on_termination = true
      volume_size           = 32
      volume_type           = "gp2"
    }
  }

  block_device_mapping {
    device_name = "/dev/sdf"

    ebs {
      delete_on_termination = true
      volume_size           = 100
      volume_type           = "gp2"
    }
  }

  systems_manager_agent {
    uninstall_after_build = false
  }

  dynamic "component" {
    for_each      = local.component_arns
    content {
      component_arn = component.value
    }
  }

  tags = var.tags
}

resource "aws_security_group" "default" {
  name        = var.image_builder_name
  description = "Security group used by temporal EC2 instance used by Image Builder"
  vpc_id      = var.image_builder_vpc_id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = var.tags
}

resource "aws_imagebuilder_infrastructure_configuration" "default" {
  name                          = var.image_builder_name
  description                   = "Infrastructure configuration for Urgently image builder"

  instance_profile_name         = aws_iam_instance_profile.builder.name
  subnet_id                     = var.image_builder_subnet_id
  terminate_instance_on_failure = true
  security_group_ids            = [aws_security_group.default.id]

  logging {
    s3_logs {
      s3_bucket_name = aws_s3_bucket.builder_data.id
      s3_key_prefix  = "logs"
    }
  }

  tags = var.tags
}

resource "aws_imagebuilder_distribution_configuration" "default" {
  name = var.image_builder_name

  distribution {
    ami_distribution_configuration {
      name = "urgently-poc-amzn2-ami-hvm-{{ imagebuilder:buildDate }}-x86_64-gp2"
    }
    region = var.region
  }
}

resource "aws_imagebuilder_image_pipeline" "urgently_poc" {
  name                             = var.image_builder_name
  image_recipe_arn                 = aws_imagebuilder_image_recipe.default.arn
  infrastructure_configuration_arn = aws_imagebuilder_infrastructure_configuration.default.arn
  distribution_configuration_arn   = aws_imagebuilder_distribution_configuration.default.arn
}
