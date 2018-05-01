output "api_address" {
  value = "${aws_elb.api.dns_name}"
}


output "tester_address" {
  value = "${aws_instance.tester.public_dns}"
}

