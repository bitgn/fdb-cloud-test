
output "tester_address" {
  value = "${aws_instance.tester.*.public_dns}"
}

output "fdb_address" {
  value = "${aws_instance.fdb.*.public_dns}"
}

