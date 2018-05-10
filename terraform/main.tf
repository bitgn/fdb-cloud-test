provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "${var.aws_region}"
}



// Find our latest available AMI for the fdb node
// TODO: switch to a shared and hosted stable image
data "aws_ami" "fdb" {
  most_recent = true
 
  filter {
    name = "name"
    values = ["bitgn-fdb"]
  }
  owners = ["self"]
}



// Find our latest available AMI for the fdb testing node
// TODO: switch to a shared and hosted stable image
data "aws_ami" "tester" {
  most_recent = true

  filter {
    name = "name"
    values = ["bitgn-tester"]
  }
  owners = ["self"]
}


# Create a VPC to launch our instances into
resource "aws_vpc" "default" {
  cidr_block = "10.0.0.0/16"
  # this will solve sudo: unable to resolve host ip-10-0-xx-xx
  enable_dns_hostnames = true

}


# Create an internet gateway to give our subnet access to the outside world
resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.default.id}"
}
# Grant the VPC internet access on its main route table
resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.default.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.default.id}"
}


# Create a subnet to launch our instances into
resource "aws_subnet" "client" {
  vpc_id                  = "${aws_vpc.default.id}"
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "Client Subnet"
    Project = "TF:bitgn"
  }
}


# Create a subnet to launch our instances into
resource "aws_subnet" "db" {
  vpc_id                  = "${aws_vpc.default.id}"
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "FDB Subnet"
    Project = "TF:bitgn"
  }
}



# security group with only SSH access
resource "aws_security_group" "tester_group" {
  name        = "tf_tester_group"
  description = "Terraform: SSH only"
  vpc_id      = "${aws_vpc.default.id}"

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# security group with only SSH access
resource "aws_security_group" "fdb_group" {
  name        = "tf_fdb_group"
  description = "Terraform: SSH and FDB"
  vpc_id      = "${aws_vpc.default.id}"

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # FDB access from the VPC
  ingress {
    from_port   = 4500
    to_port     = 4500
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_key_pair" "auth" {
  key_name   = "${var.key_name}"
  public_key = "${file(var.public_key_path)}"
}


resource "aws_instance" "tester" {
  # The connection block tells our provisioner how to
  # communicate with the resource (instance)
  connection {
    # The default username for our AMI
    user = "ubuntu"
    agent = "false"

    private_key = "${file(var.private_key_path)}"
    # The connection will use the local SSH agent for authentication.
  }


  instance_type = "${var.aws_tester_size}"

  # Grab AMI id from the data source
  ami = "${data.aws_ami.tester.id}"

  # The name of our SSH keypair we created above.
  key_name = "${aws_key_pair.auth.id}"

  # Our Security group to allow HTTP and SSH access
  vpc_security_group_ids = ["${aws_security_group.tester_group.id}"]

  # We're going to launch into the client subnet.
  subnet_id = "${aws_subnet.client.id}"

  tags {
    Name = "Tester"
    Project = "TF:bitgn"
  }



  provisioner "remote-exec" {
    inline = [
      # resolve IP address as host name
      "echo \"${self.private_ip} $(hostname)\" | sudo tee -a /etc/hosts",
      # install default FDB cluster file
      "echo \"Drtu0T4S:i8uQIB9r@${cidrhost(aws_subnet.db.cidr_block, 101)}:4500\" | sudo tee /etc/foundationdb/fdb.cluster"
    ]
  }
}



resource "aws_instance" "fdb" {
  # The connection block tells our provisioner how to
  # communicate with the resource (instance)
  connection {
    # The default username for our AMI
    user = "ubuntu"
    agent = "false"

    private_key = "${file(var.private_key_path)}"
    # The connection will use the local SSH agent for authentication.
  }


  instance_type = "${var.aws_fdb_size}"
  count = "${var.aws_fdb_count}"
  # Grab AMI id from the data source
  ami = "${data.aws_ami.fdb.id}"


  # I want a very specific IP address to be assigned. However
  # AWS reserves both the first four IP addresses and the last IP address
  # in each subnet CIDR block. They're not available for you to use.
  private_ip = "${cidrhost(aws_subnet.db.cidr_block, count.index+1+100)}"


  # The name of our SSH keypair we created above.
  key_name = "${aws_key_pair.auth.id}"

  # Our Security group to allow HTTP and SSH access
  vpc_security_group_ids = ["${aws_security_group.fdb_group.id}"]

  # We're going to launch into the DB subnet
  subnet_id = "${aws_subnet.db.id}"

  tags {
    Name = "${format("fdb-%03d", count.index + 1)}"
    Project = "TF:bitgn"
  }

  provisioner "remote-exec" {
    inline = [
      # stop the service to keep things simple and quiet
      "sudo service foundationdb stop",
      # resolve IP address as host name
      "echo \"${self.private_ip} $(hostname)\" | sudo tee -a /etc/hosts",
      # wipe the data from the image
      "sudo rm -rf /var/lib/foundationdb/data/4500/",
      # make 1st node the coordinator
      "echo \"Drtu0T4S:i8uQIB9r@${cidrhost(aws_subnet.db.cidr_block, 101)}:4500\" | sudo tee /etc/foundationdb/fdb.cluster",
      # make sure the cluster file is writeable by everybody
      "sudo chmod ugo+w /etc/foundationdb/fdb.cluster",
      # non-seed nodes sleep a bit
      "${count.index == 0 ? "echo Leader setup" : "sleep 20"}",
      # restart the FDB service to make things happen. Leader will start first
      # follower nodes - 20 seconds later
      "sudo service foundationdb start && sleep 5",
      # leader will sleep 40 seconds after the nodes (allowing nodes to join) and configure
      "${count.index == 0 ? "sleep 60 && fdbcli --exec \"configure new memory double; coordinators auto; status\" --timeout 60" : "echo follower"}"
    ]
  }
}
