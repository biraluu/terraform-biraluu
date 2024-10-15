#terraform demo-project by ayush_devops_intern_xuno








#initial setup

provider "aws" {
    region     = "ap-southeast-2"
    access_key = var.aws_access_key
    secret_key = var.aws_secret_key
}


#1 creating a vpc 

resource "aws_vpc" "prod-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "production"
    }
}

#2 creating internet gateway

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.prod-vpc.id 
}

#3 creating custom routing table
resource "aws_route_table" "prod-route-table" {
  vpc_id = aws_vpc.prod-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
     ipv6_cidr_block = "::/0"
     gateway_id = aws_internet_gateway.gw.id
  }
  
  tags = {
    Name = "prod"
  }
}

#4 create a subnet

resource "aws_subnet" "subnet-1" {
  vpc_id = aws_vpc.prod-vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-southeast-2a"

  tags = {
    Name = "prod-subnet"
  } 
}

#5 associating a subnet with route table

resource "aws_route_table_association" "a" {
  subnet_id = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.prod-route-table.id
  
}

#6 creating security groups

resource "aws_security_group" "allow-web" {
  name = "allow_web_traffic"
  description = "allow web inbound traffic"
  vpc_id = aws_vpc.prod-vpc.id

  ingress {
    description = "https"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    description = "http"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "allow_web"
  }
}

#7 creating a network interface with an ip in the subnet that was created in step 4

resource "aws_network_interface" "web-server-ayush" {
  subnet_id = aws_subnet.subnet-1.id
  private_ips = ["10.0.1.50"]
  security_groups = [aws_security_group.allow-web.id]
}

#8 assigning an elastic ip to the network interface created in step 7

resource "aws_eip" "one" {
  domain                    = "vpc"
  network_interface         = aws_network_interface.web-server-ayush.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [aws_instance.web-server-instance]

}

# resource "aws_eip" "one" {
#   vpc = true
#   network_interface = aws_network_interface.web-server-ayush.id
#   associate_with_private_ip = "10.0.1.50"
#   depends_on = [aws_internet_gateway.gw]
# }

# resource "aws_eip_association" "one" {
#   allocation_id        = aws_eip.one.id
#   network_interface_id = aws_network_interface.web-server-ayush.id
#   private_ip_address   = "10.0.1.50"
# }

resource "aws_instance" "web-server-instance" {
  ami = "ami-001f2488b35ca8aad"
  instance_type = "t2.micro"
  availability_zone = "ap-southeast-2a"
  key_name = "main-key"

  network_interface {
    device_index = "0"
    network_interface_id = aws_network_interface.web-server-ayush.id
  }

  user_data = <<-EOF
              #!bin/bash
              sudo apt update -y
              sudo apt install apache2 -y
              sudo systemctl start apache2
              sudo bash -c 'echo welcome back guy, this is working ! happy returning from dashain ! > /var/www/html/index.html'
              EOF
  tags = {
    Name = "web-server"
  }
}

















# resource "aws_subnet" "subnet-1" {
#   vpc_id = aws_vpc.first-vpc.id
#   cidr_block = "10.0.1.0/24"

#   tags = {
#     Name = "prod-subnet"
#   }
  
# }

# resource "aws_instance" "example" {
#   ami = "ami-001f2488b35ca8aad"
#   instance_type = "t2.micro"
# }

# resource "aws" "ec2" {
#     config options =
#     key = value
#     key2 = value2
  
# }