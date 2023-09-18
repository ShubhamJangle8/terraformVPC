provider "aws" {
    region = "us-east-2"
}

variable "ami_id" {
    default = "ami-024e6efaf93d85776"
}

variable "instance_name1" {
    default = "TerraPublic"
}
variable "instance_name2" {
    default = "TerraPrivate"
}
variable "key_name" {
    default = "macohiokeypair"
}

variable "cidr" {
    default = "10.1.0.0/16"
}

variable "instance_type" {
    default = "t2.micro"
}

resource "aws_vpc" "myvpc" {
    cidr_block = var.cidr
}

resource "aws_subnet" "mysubnet1" {
    vpc_id = aws_vpc.myvpc.id
    cidr_block = "10.1.1.0/24"
    availability_zone = "us-east-2a"
    map_public_ip_on_launch = true
}

resource "aws_subnet" "mysubnet2" {
    vpc_id = aws_vpc.myvpc.id
    cidr_block = "10.1.2.0/24"
    availability_zone = "us-east-2a"
}

resource "aws_internet_gateway" "ig" {
    vpc_id = aws_vpc.myvpc.id
}

resource "aws_route_table" "rt1" {
    vpc_id = aws_vpc.myvpc.id
    tags = {
        Name = "MyPublicRouteTable"
    }
}

resource "aws_route_table" "rt2" {
    vpc_id = aws_vpc.myvpc.id
    tags = {
        Name = "MyPrivateRouteTable"
    }
}

resource "aws_route" "route1" {
    route_table_id = aws_route_table.rt1.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ig.id
}

resource "aws_eip" "eip" {
  # No "instance" attribute specified here
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.eip.id
  subnet_id = aws_subnet.mysubnet1.id
}

resource "aws_route" "route2" {
    route_table_id = aws_route_table.rt1.id
    destination_cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "rta1" {
    subnet_id = aws_subnet.mysubnet1.id
    route_table_id = aws_route_table.rt1.id
}

resource "aws_route_table_association" "rta2" {
    subnet_id = aws_subnet.mysubnet2.id
    route_table_id = aws_route_table.rt2.id
}

resource "aws_security_group" "websg" {
    vpc_id = aws_vpc.myvpc.id
    ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Web-sg"
  }
}

resource "aws_instance" "ec2_instance1" {
    ami = var.ami_id
    instance_type = var.instance_type
    vpc_security_group_ids = [aws_security_group.websg.id]
    subnet_id = aws_subnet.mysubnet1.id
    tags = {
        Name = var.instance_name1
    }
    key_name = var.key_name
}

resource "aws_instance" "ec2_instance2" {
    ami = var.ami_id
    instance_type = var.instance_type
    vpc_security_group_ids = [aws_security_group.websg.id]
    subnet_id = aws_subnet.mysubnet2.id
    tags = {
        Name = var.instance_name2
    }
    key_name = var.key_name
}

output "public_ip1" {
    value = aws_instance.ec2_instance1.public_ip
}
/*output "public_ip2" {
    value = aws_instance.ec2_instance2.public_ip
}*/
output "subnet_id" {
    value = aws_subnet.mysubnet2.id
}
output "eip" {
    value = aws_eip.eip.id
}
output "rt_id" {
    value = aws_route_table.rt1.id
}