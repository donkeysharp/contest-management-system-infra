variable "region" {
  type        = string
  description = "AWS region"
  default     = "us-east-1"
}

variable "environment" {
  type        = string
  description = "Environment name"
  default     = "dev"
}

variable "image_builder_base_ami_id" {
  type        = string
  description = "AMI id of base image for builder."
  /*
   * This image is owned by Urgently and created based on an old version of Amazon Linux 2 from 2020
   * urgently-poc-amzn2-ami-hvm-2.0.20201218.1-x86_64-gp2
   */
  default     = "ami-0863830c641f3a84b"
}

variable "image_builder_subnet_id" {
  type        = string
  description = "Subnet id for the temporal EC2 instance that will be created by Image Builder"
  default     = "subnet-05cbf9d9dcf0917f1"
}

variable "image_builder_vpc_id" {
  type        = string
  description = "VPC id for the temporal EC2 instance that will be created by Image Builder"
  default     = "vpc-0fa4865184c0b46ff"
}
