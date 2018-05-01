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
    values = ["bitgn-tester*"]
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
resource "aws_subnet" "elb" {
  vpc_id                  = "${aws_vpc.default.id}"
  cidr_block              = "10.0.9.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "ELB Subnet"
    Project = "TF:bitgn"
  }
}


# Create a subnet to launch our instances into
resource "aws_subnet" "backend" {
  vpc_id                  = "${aws_vpc.default.id}"
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "Backend Subnet"
    Project = "TF:bitgn"
  }
}


# Create a subnet to launch our instances into
resource "aws_subnet" "db" {
  vpc_id                  = "${aws_vpc.default.id}"
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "DB Subnet"
    Project = "TF:bitgn"
  }
}


# A security group for the ELB so it is accessible via the web
resource "aws_security_group" "elb_group" {
  name        = "tf_elb_group"
  description = "Terraform: HTTP"
  vpc_id      = "${aws_vpc.default.id}"

  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
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

# Our default security group to access
# the instances over SSH and HTTP
resource "aws_security_group" "api_group" {
  name        = "tf_api_group"
  description = "Terraform: SSH + HTTP"
  vpc_id      = "${aws_vpc.default.id}"

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access from the VPC
  ingress {
    from_port   = 80
    to_port     = 80
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


# security group to access InfluxDB server
resource "aws_security_group" "metrics_group" {
  name        = "tf_metrics_group"
  description = "Terraform: SSH + HTTP + Metrics"
  vpc_id      = "${aws_vpc.default.id}"

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Influx Admin Access inside the network
  ingress {
    from_port   = 8083
    to_port     = 8083
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # influx DB client-server API
  ingress {
    from_port   = 8086
    to_port     = 8086
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }


  # Influx - Grafana access inside the network
  ingress {
    from_port   = 80
    to_port     = 80
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


resource "aws_elb" "api" {
  name = "tf-bitgn-elb"

  subnets         = ["${aws_subnet.elb.id}"]
  security_groups = ["${aws_security_group.elb_group.id}"]
  instances       = ["${aws_instance.api.*.id}"]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

}


resource "aws_key_pair" "auth" {
  key_name   = "${var.key_name}"
  public_key = "${file(var.public_key_path)}"
}

resource "aws_instance" "api" {
  # The connection block tells our provisioner how to
  # communicate with the resource (instance)
  connection {
    # The default username for our AMI
    user = "admin"
    agent = "false"
    private_key = "${var.private_key_path}"

    # The connection will use the local SSH agent for authentication.
  }

  instance_type = "${var.aws_api_size}"
  count = "${var.aws_api_count}"

  # Lookup the correct AMI based on the region
  # we specified
  ami = "${lookup(var.aws_api_amis, var.aws_region)}"

  # The name of our SSH keypair we created above.
  key_name = "${aws_key_pair.auth.id}"

  # Our Security group to allow HTTP and SSH access
  vpc_security_group_ids = ["${aws_security_group.api_group.id}"]

  subnet_id = "${aws_subnet.backend.id}"

  # I want a very specific IP address to be assigned. However
  # AWS reserves both the first four IP addresses and the last IP address
  # in each subnet CIDR block. They're not available for you to use.
  private_ip = "${cidrhost(aws_subnet.backend.cidr_block, count.index+1+100)}"

  # We run a remote provisioner on the instance after creating it.
  # In this case, we just install nginx and start it. By default,
  # this should be on port 80
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get -y update",
      "sudo apt-get -y install nginx",
      "sudo service nginx start"
    ]
  }

  tags {
    Name = "${format("api-%03d", count.index + 1)}"
    Project = "TF:bitgn"
  }
}


resource "aws_instance" "tester" {
  # The connection block tells our provisioner how to
  # communicate with the resource (instance)
  connection {
    # The default username for our AMI
    user = "admin"
    agent = "false"

    private_key = "${var.private_key_path}"
    # The connection will use the local SSH agent for authentication.
  }

  instance_type = "${var.aws_tester_size}"

  # Grab AMI id from the data source
  ami = "${data.aws_ami.tester.id}"

  # The name of our SSH keypair we created above.
  key_name = "${aws_key_pair.auth.id}"

  # Our Security group to allow HTTP and SSH access
  vpc_security_group_ids = ["${aws_security_group.tester_group.id}"]

  # We're going to launch into the same subnet as our ELB. In a production
  # environment it's more common to have a separate private subnet for
  # backend instances.
  subnet_id = "${aws_subnet.backend.id}"

  tags {
    Name = "Tester"
    Project = "TF:bitgn"
  }



  provisioner "remote-exec" {
    inline = [
      # resolve IP address as host name
      "echo \"${self.private_ip} $(hostname)\" | sudo tee -a /etc/hosts",
      # install default FDB cluster file
      "echo \"Drtu0T4S:SdzTe7B4@${cidrhost(aws_subnet.db.cidr_block, 101)}:4500\" | sudo tee /etc/foundationdb/fdb.cluster"
    ]
  }
}



resource "aws_instance" "fdb" {
  # The connection block tells our provisioner how to
  # communicate with the resource (instance)
  connection {
    # The default username for our AMI
    user = "admin"
    agent = "false"
    private_key = "${var.private_key_path}"
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
      # resolve IP address as host name
      "echo \"${self.private_ip} $(hostname)\" | sudo tee -a /etc/hosts",
      # make 1st node the coordinator, file in the image is writeable
      "echo \"Drtu0T4S:SdzTe7B4@${cidrhost(aws_subnet.db.cidr_block, 101)}:4500\" | sudo tee /etc/foundationdb/fdb.cluster",
      # restart the FDB to make things happen
      "sudo service foundationdb restart",
      # configure first server
      "test ${count.index} -eq 0 && sleep 5 && fdbcli --exec \"configure new double ssd; status\" --timeout 60 || echo \"not a leader\""
    ]
  }
}


resource "aws_route53_record" "dns_api" {
  zone_id = "${var.aws_route53_zone}"
  name = "api"
  type = "A"

  alias {
    name = "${aws_elb.api.dns_name}"
    zone_id = "${aws_elb.api.zone_id}"
    evaluate_target_health = true
  }
}
resource "aws_route53_record" "dns_dev" {
  zone_id = "${var.aws_route53_zone}"
  name = "dev"
  type = "CNAME"
  ttl = "300"
  records = ["${aws_instance.tester.public_dns}"]
}
