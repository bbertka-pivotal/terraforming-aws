locals {
  public_cidr     = "${cidrsubnet(var.vpc_cidr, 6, 0)}"
  infrastructure_cidr = "${cidrsubnet(var.vpc_cidr, 10, 64)}"
  pas_cidr        = "${cidrsubnet(var.vpc_cidr, 6, 1)}"
  services_cidr   = "${cidrsubnet(var.vpc_cidr, 6, 2)}"
}

resource "aws_subnet" "public_subnets" {
  count             = "${length(var.availability_zones)}"
  vpc_id            = "${aws_vpc.vpc.id}"
  cidr_block        = "${cidrsubnet(local.public_cidr, 2, count.index)}"
  availability_zone = "${element(var.availability_zones, count.index)}"

  tags = "${merge(var.tags, local.default_tags,
    map("Name", "${var.env_name}-public-subnet${count.index}")
  )}"
}

resource "aws_subnet" "infrastructure_subnets" {
  count             = "${length(var.availability_zones)}"
  vpc_id            = "${aws_vpc.vpc.id}"
  cidr_block        = "${cidrsubnet(local.infrastructure_cidr, 2, count.index)}"
  availability_zone = "${element(var.availability_zones, count.index)}"

  tags = "${merge(var.tags, local.default_tags,
    map("Name", "${var.env_name}-infrastructure-subnet${count.index}")
  )}"
}

data "template_file" "infrastructure_subnet_gateways" {
  # Render the template once for each availability zone
  count    = "${length(var.availability_zones)}"
  template = "$${gateway}"

  vars {
    gateway = "${cidrhost(element(aws_subnet.infrastructure_subnets.*.cidr_block, count.index), 1)}"
  }
}

resource "aws_subnet" "pas_subnets" {
  count             = "${length(var.availability_zones)}"
  vpc_id            = "${aws_vpc.vpc.id}"
  cidr_block        = "${cidrsubnet(local.pas_cidr, 2, count.index)}"
  availability_zone = "${element(var.availability_zones, count.index)}"

  tags {
    Name = "${var.env_name}-ert-subnet${count.index}"
  }
}

data "template_file" "pas_subnet_gateways" {
  # Render the template once for each availability zone
  count    = "${length(var.availability_zones)}"
  template = "$${gateway}"

  vars {
    gateway = "${cidrhost(element(aws_subnet.pas_subnets.*.cidr_block, count.index), 1)}"
  }
}

resource "aws_subnet" "services_subnets" {
  count             = "${length(var.availability_zones)}"
  vpc_id            = "${aws_vpc.vpc.id}"
  cidr_block        = "${cidrsubnet(local.services_cidr, 2, count.index)}"
  availability_zone = "${element(var.availability_zones, count.index)}"

  tags = "${merge(var.tags, local.default_tags,
    map("Name", "${var.env_name}-services-subnet${count.index}")
  )}"
}

data "template_file" "services_subnet_gateways" {
  # Render the template once for each availability zone
  count    = "${length(var.availability_zones)}"
  template = "$${gateway}"

  vars {
    gateway = "${cidrhost(element(aws_subnet.services_subnets.*.cidr_block, count.index), 1)}"
  }
}
