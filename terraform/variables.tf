variable "public_key_path" {
  description = "Path to the SSH public key to be used for authentication."
  default = "~/.ssh/terraform.pub"
}

variable "private_key_path" {
  description = "Path to the SSH private key"
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

variable "aws_fdb_size" {
  default = "t2.medium"
  description = "machine type to run FoundationDB servers"

}
# using only 1 machine will conflict with the default cluster config
# 'configure new memory double'
variable "aws_fdb_count" {
  default = 3
  description = "how many machines do we want in our cluster. Minimum 2"
}

variable "aws_tester_size" {
  default = "m4.xlarge"
  description = "instance type for launching tester machines"
}

