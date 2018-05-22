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

variable "aws_availability_zone" {
  default = "eu-central-1b"
}


// instance store options: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/InstanceStorage.html

# good options:
# i3.large - will use local NVMe SSD
# m3.large - will use local instance store

variable "aws_fdb_size" {
  default = "m3.large"
  description = "machine type to run FoundationDB servers"
}
variable "fdb_procs_per_machine" {
  default = 2
  description = "number of FDB processes per machine"
}
# using only 1 machine will conflict with the default cluster config
# 'configure new memory double'
variable "aws_fdb_count" {
  default = 3
  description = "Number of machines in a cluster. Minimum 2"
}


# good options
# m3.large
# c5.2xlarge
variable "aws_tester_size" {
  default = "m3.large"
  description = "instance type for launching tester machines"
}

