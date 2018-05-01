variable "public_key_path" {
  description = <<DESCRIPTION
Path to the SSH public key to be used for authentication.
Ensure this keypair is added to your local SSH agent so provisioners can
connect.
DESCRIPTION
  default = "~/.ssh/terraform.pub"
}

variable "private_key_path" {
  default = "~/.ssh/terraform"
}

variable "key_name" {
   default = "terraform"
}


variable "aws_access_key" {}
variable "aws_secret_key" {}

variable "aws_region" {
  default = "eu-central-1"
  description = "AWS region to launch servers."
}

variable "aws_route53_zone" {
  default = "Z3V0R1YFJOFP34"
  description = "Domain name into which we'll plug records"
}



# pre-baked tester
variable "aws_tester_size" {
  default = "m4.xlarge"
}

variable "aws_fdb_size" {
  default = "t2.medium"
}
variable "aws_fdb_count" {
  default = 5
}



variable "aws_api_size" {
  default = "t2.small"
}
variable "aws_api_count" {
  default = 0
}
variable "aws_api_amis" {
  type = "map"
  default = {
    eu-central-1 = "ami-ccc021a3"
  }
}
