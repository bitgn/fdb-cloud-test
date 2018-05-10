Status: unstable (update is in progress)

# About

The purpose of this project is to make it easy to run various load
tests on systems with FoundationDB in the cloud.

We can achieve that by:

1. "Prebaking" cloud-specific VM images for the FoundationDB cluster
   nodes along with the tester nodes and machines for capturing the
   telemetry.
2. Using these images to quickly create FoundationDB clusters with the
   specific configuration.

The first step is handled by the [Packer](https://www.packer.io), the
second - by the [Terraform](https://www.terraform.io)

Initial plan is to have a setup with a fixed topology:

- FoundationDB nodes in the same network
- Load tester machines connected to the same network

Number and VM type for the node and load tester machines could be
changed within the configuration.

# Creating AMIs

First you need to create packer images for FDB nodes and tester
nodes. You can do this:
```
$ export AWS_ACCESS_KEY=""
$ export AWS_SECRET_KEY=""
$ cd packer-fdb
$ packer build --only=aws packer.json
```

Tester AMI can be created exactly like this but you enter
`packer-tester` folder instead.


# Cleanup

This project was started by Rinat Abdullin a while ago as a platform
for experimenting with FoundationDB. As such it has accumulated some
layers and extensions that may be unnecessary.

The project also uses old versions of FoundationDB and all the
dependencies, so these will need to be updated.


We also include all the dependencies in binary form in github. It was 
worth it before the code was open source and repository size wasn't a 
big concern. Things could be different now.
