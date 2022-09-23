# Configure the AWS Provider
provider "aws" {
    region = "eu-west-2"
    #shared_credentials_files = "C:\\Users\\Admin\\.aws\\credentials"
    access_key = var.access_key
    secret_key = var.secret_key
}

#Transit VPC
resource "aws_vpc" "Transit_VPC" {
  cidr_block       = "10.0.4.0/23"
  instance_tenancy = "default"

  tags = {
    Name = "Transit_VPC"
  }
}

#Transit Internet Gateway
resource "aws_internet_gateway" "Transit_Internet_Gateway" {
  vpc_id = aws_vpc.Transit_VPC.id

  tags = {
    Name = "Transit_Internet_Gateway"
  }
}

# Transit Default Route Table
resource "aws_default_route_table" "Transit_Route_Table" {
  default_route_table_id = aws_vpc.Transit_VPC.default_route_table_id

  # route destined to Prod subnet with a next hop to this VPC Peering
  route {
    cidr_block = "10.0.1.0/25"
    vpc_peering_connection_id = aws_vpc_peering_connection.Transit_and_Production_VPC_Peering.id
  }

  # route destined to the shared subnet with a next hop to this VPC Peering
  route {
    cidr_block = "10.0.2.0/25"
    vpc_peering_connection_id = aws_vpc_peering_connection.Transit_and_Shared_VPC_Peering.id
  }

  # route destined to the dev subnet with a next hop to this VPC Peering
  route {
    cidr_block = "10.0.3.0/25"
    vpc_peering_connection_id = aws_vpc_peering_connection.Transit_and_Dev_VPC_Peering.id
  }

  tags = {
    Name = "Transit_Route_Table"
  }
}

#Transit Default Security Group
resource "aws_default_security_group" "Transit_Security_Group" {
  vpc_id = aws_vpc.Transit_VPC.id

  ingress {
    protocol  = -1
    self      = true
    from_port = 0
    to_port   = 0
  }

  ingress {
    protocol = "icmp"
    from_port = -1
    to_port = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#Transit Management Subnet
resource "aws_subnet" "Transit_Management_Subnet" {
  vpc_id     = aws_vpc.Transit_VPC.id
  cidr_block = "10.0.4.0/26"
  map_public_ip_on_launch = true

  tags = {
    Name = "Transit_Management_Subnet"
  }
}

#Transit Private Subnet
resource "aws_subnet" "Transit_Private_Subnet" {
  vpc_id     = aws_vpc.Transit_VPC.id
  cidr_block = "10.0.4.64/26"

  tags = {
    Name = "Transit_Private_Subnet"
  }
}

#Transit Public Subnet
resource "aws_subnet" "Transit_Public_Subnet" {
  vpc_id     = aws_vpc.Transit_VPC.id
  cidr_block = "10.0.4.128/26"

  tags = {
    Name = "Transit_Public_Subnet"
  }
}

#######################################################################################

#Management VPC
resource "aws_vpc" "Management_VPC" {
  cidr_block       = "10.0.0.0/24"
  instance_tenancy = "default"

  tags = {
    Name = "Management_VPC"
  }
  
}

# Management Internet Gateway
resource "aws_internet_gateway" "Management_Internet_Gateway" {
  vpc_id = aws_vpc.Management_VPC.id

  tags = {
    Name = "Management_Internet_Gateway"
  }
}

# Management Default Route Table
resource "aws_default_route_table" "Management_Route_Table" {
  default_route_table_id = aws_vpc.Management_VPC.default_route_table_id

  #Route destined to the internet with a next hop of the Management IGW
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Management_Internet_Gateway.id
  }

  #Route destined to Production subnet with a next hop to the Mgt-ti-Prod VPC Peering
  route {
    cidr_block = "10.0.1.0/25"
    vpc_peering_connection_id = aws_vpc_peering_connection.Management_and_Production_VPC_Peering.id
  }

  #Route destined to Dev subnet with a next hop to the Mgt-to-Dev VPC Peering
  route {
    cidr_block = "10.0.3.0/25"
    vpc_peering_connection_id = aws_vpc_peering_connection.Management_and_Dev_VPC_Peering.id
  }

  #Route destined to Shared subnet with a next hop to the Mgt-to-Shared VPC Peering
  route {
    cidr_block = "10.0.2.0/25"
    vpc_peering_connection_id = aws_vpc_peering_connection.Management_and_Shared_VPC_Peering.id
  }


  tags = {
    Name = "Management_Route_Table"
  }
}

#Management Subnet
resource "aws_subnet" "Management_Subnet" {
  vpc_id     = aws_vpc.Management_VPC.id
  cidr_block = "10.0.0.0/25"

  tags = {
    Name = "Management_Subnet"
  }
}

#Management Default Security Group
resource "aws_default_security_group" "Management_Security_Group" {
  vpc_id = aws_vpc.Management_VPC.id

  ingress {
    protocol  = -1
    self      = true
    from_port = 0
    to_port   = 0
  }

  ingress {
    protocol = "tcp"
    from_port = 22
    to_port = 22
    cidr_blocks = ["10.0.0.0/8", "0.0.0.0/0"]
  }

  ingress {
    protocol  = "icmp"
    from_port = -1
    to_port   = -1
    cidr_blocks = ["10.0.0.0/8", "0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#EC2 Instance-Management
resource "aws_instance" "Management-Linux" {
  ami           = "ami-06672d07f62285d1d"
  instance_type = "t2.micro"
  associate_public_ip_address = true
  key_name = var.key_name
  subnet_id = aws_subnet.Management_Subnet.id

  tags = {
    Name = "Management-Linux"
  }
}

#######################################################################################

#Production VPC
resource "aws_vpc" "Production_VPC" {
  cidr_block       = "10.0.1.0/24"
  instance_tenancy = "default"

  tags = {
    Name = "Production_VPC"
  }
  
}

#Prod Default Route Table
resource "aws_default_route_table" "Production_Route_Table" {
  default_route_table_id = aws_vpc.Production_VPC.default_route_table_id

  #Route destined to the Transit subnet, with the next hop to this VPC Peering
  route {
    cidr_block = "10.0.4.0/26"
    vpc_peering_connection_id = aws_vpc_peering_connection.Transit_and_Production_VPC_Peering.id
  }

  #Route destinied to the shared subnet, with the next hop to this VPC Peering
  route {
    cidr_block = "10.0.2.0/25"
    vpc_peering_connection_id = aws_vpc_peering_connection.Shared_and_Production_VPC_Peering.id
  }

  #Route destined to the internet subnet, with the next hop of Transit_and_Production-VPC Peering
  route {
    cidr_block = "0.0.0.0/0"
    vpc_peering_connection_id = aws_vpc_peering_connection.Transit_and_Production_VPC_Peering.id
  }

  #Route destined to the management subnet, with the next hop of Management and Prod
  route {
    cidr_block = "10.0.0.0/25"
    vpc_peering_connection_id = aws_vpc_peering_connection.Management_and_Production_VPC_Peering.id
  }

  tags = {
    Name = "Production_Route_Table"
  }
}

#Prod Default Security Group
resource "aws_default_security_group" "Production_Security_Group" {
  vpc_id = aws_vpc.Production_VPC.id

  ingress {
    protocol  = -1
    self      = true
    from_port = 0
    to_port   = 0
  }

  ingress {
    protocol = "tcp"
    from_port = 22
    to_port = 22
    cidr_blocks = ["10.0.0.0/8"]
  }

  ingress {
    protocol  = "icmp"
    from_port = -1
    to_port   = -1
    cidr_blocks = ["10.0.0.0/8", "0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#Prod Subnet
resource "aws_subnet" "Production_Subnet" {
  vpc_id     = aws_vpc.Production_VPC.id
  cidr_block = "10.0.1.0/25"

  tags = {
    Name = "Production_Subnet"
  }
}

#EC2 Instance-Production
resource "aws_instance" "Production-Linux" {
  ami           = "ami-06672d07f62285d1d"
  instance_type = "t2.micro"
  key_name = var.key_name
  subnet_id = aws_subnet.Production_Subnet.id

  tags = {
    Name = "Production-Linux"
  }
}

#####################################################################################

# Shared VPC
resource "aws_vpc" "Shared_VPC" {
  cidr_block       = "10.0.2.0/24"
  instance_tenancy = "default"

  tags = {
    Name = "Shared_VPC"
  }
  
}

#Shared Default Route Table
resource "aws_default_route_table" "Shared_Route_Table" {
  default_route_table_id = aws_vpc.Shared_VPC.default_route_table_id

  #Route destined to Prod subnet with a next hop to the Shared-to-Prod VPC Peering
  route {
    cidr_block = "10.0.1.0/25"
    vpc_peering_connection_id = aws_vpc_peering_connection.Shared_and_Production_VPC_Peering.id
  }

  #Route destined to Dev subnet with a next hop to the Shared-to-Dev VPC Peering
  route {
    cidr_block = "10.0.3.0/25"
    vpc_peering_connection_id = aws_vpc_peering_connection.Shared_and_Dev_VPC_Peering.id
  }

  #Route destined to the Transit Management subnet, with the next hop to this VPC Peering
  route {
    cidr_block = "10.0.4.0/26"
    vpc_peering_connection_id = aws_vpc_peering_connection.Shared_and_Dev_VPC_Peering.id
  }

  #Route destined to the Management subnet, with the next hop of management-and-shared perring
  route {
    cidr_block = "10.0.0.0/25"
    vpc_peering_connection_id = aws_vpc_peering_connection.Management_and_Shared_VPC_Peering.id
  }

  #Route destined to the management subnet, with the next hop of Management-and-Dev-VPC Peering
  route {
    cidr_block = "0.0.0.0/0"
    vpc_peering_connection_id = aws_vpc_peering_connection.Transit_and_Shared_VPC_Peering.id
  }

  tags = {
    Name = "Shared_Route_Table"
  }
}

#Shared Default Security Group
resource "aws_default_security_group" "Shared_Security_Group" {
  vpc_id = aws_vpc.Shared_VPC.id

  ingress {
    protocol  = -1
    self      = true
    from_port = 0
    to_port   = 0
  }

  ingress {
    protocol = "tcp"
    from_port = 22
    to_port = 22
    cidr_blocks = ["10.0.0.0/8"]
  }

  ingress {
    protocol  = "icmp"
    from_port = -1
    to_port   = -1
    cidr_blocks = ["10.0.0.0/8", "0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#Shared Subnet
resource "aws_subnet" "Shared_Subnet" {
  vpc_id     = aws_vpc.Shared_VPC.id
  cidr_block = "10.0.2.0/25"

  tags = {
    Name = "Shared_Subnet"
  }
}

#EC2 Instance-Shared
resource "aws_instance" "Shared-Linux" {
  ami           = "ami-06672d07f62285d1d"
  instance_type = "t2.micro"
  key_name = var.key_name
  subnet_id = aws_subnet.Shared_Subnet.id

  tags = {
    Name = "Shared-Linux"
  }
}

#####################################################################################

#Dev VPC
resource "aws_vpc" "Dev_VPC" {
  cidr_block       = "10.0.3.0/24"
  instance_tenancy = "default"

  tags = {
    Name = "Dev_VPC"
  }
  
}

#Dev Default Route Table
resource "aws_default_route_table" "Dev_Route_Table" {
  default_route_table_id = aws_vpc.Dev_VPC.default_route_table_id

  #Route destined to the Transit Management subnet woth a next hop of the Transit and Dev VPC
  route {
    cidr_block = "10.0.4.0/26"
    vpc_peering_connection_id = aws_vpc_peering_connection.Transit_and_Dev_VPC_Peering.id
  }

  #Route destined to the Shared Subnet, with the next hop to Shared-and-Dev VPC Peering
  route {
    cidr_block = "10.0.2.0/25"
    vpc_peering_connection_id = aws_vpc_peering_connection.Shared_and_Dev_VPC_Peering.id
  }

  #Route destined to the management subnet, with the next hop of Management-and-Dev-VPC Peering
  route {
    cidr_block = "10.0.0.0/25"
    vpc_peering_connection_id = aws_vpc_peering_connection.Management_and_Dev_VPC_Peering.id
  }

  #Route destined to the management subnet, with the next hop of Management-and-Dev-VPC Peering
  route {
    cidr_block = "0.0.0.0/0"
    vpc_peering_connection_id = aws_vpc_peering_connection.Transit_and_Dev_VPC_Peering.id
  }

  tags = {
    Name = "Dev_Route_Table"
  }
}

#Dev Default Security Group
resource "aws_default_security_group" "Dev_Security_Group" {
  vpc_id = aws_vpc.Dev_VPC.id

  ingress {
    protocol  = -1
    self      = true
    from_port = 0
    to_port   = 0
  }

  ingress {
    protocol = "tcp"
    from_port = 22
    to_port = 22
    cidr_blocks = ["10.0.0.0/8"]
  }

  ingress {
    protocol  = "icmp"
    from_port = -1
    to_port   = -1
    cidr_blocks = ["10.0.0.0/8", "0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#Dev Subnet
resource "aws_subnet" "Dev_Subnet" {
  vpc_id     = aws_vpc.Dev_VPC.id
  cidr_block = "10.0.3.0/25"

  tags = {
    Name = "Dev_Subnet"
  }
}

#EC2 Instance-Management
resource "aws_instance" "Dev-Linux" {
  ami           = "ami-06672d07f62285d1d"
  instance_type = "t2.micro"
  key_name = var.key_name
  subnet_id = aws_subnet.Dev_Subnet.id

  tags = {
    Name = "Dev-Linux"
  }
}

#########################################################################

#Management-and-Prod VPC Peering
resource "aws_vpc_peering_connection" "Management_and_Production_VPC_Peering" {
  peer_owner_id = var.peer_owner_id
  peer_vpc_id   = aws_vpc.Management_VPC.id #VPC Accepter; server
  vpc_id        = aws_vpc.Production_VPC.id #VPC Requester; client
  auto_accept   = true

  tags = {
    Name = "VPC Peering between Management and Production VPCs"
  }
}

#Management-and-Dev VPC Peering
resource "aws_vpc_peering_connection" "Management_and_Dev_VPC_Peering" {
  peer_owner_id = var.peer_owner_id
  peer_vpc_id   = aws_vpc.Management_VPC.id #VPC Accepter; server
  vpc_id        = aws_vpc.Dev_VPC.id #VPC Requester; client
  auto_accept   = true

  tags = {
    Name = "VPC Peering between Management and Dev VPCs"
  }
}

#Management-and-Shared VPC Peering
resource "aws_vpc_peering_connection" "Management_and_Shared_VPC_Peering" {
  peer_owner_id = var.peer_owner_id
  peer_vpc_id   = aws_vpc.Management_VPC.id #VPC Accepter; server
  vpc_id        = aws_vpc.Shared_VPC.id #VPC Requester; client
  auto_accept   = true

  tags = {
    Name = "VPC Peering between Management and Shared VPCs"
  }
}

#Shared-and-Production VPC Peering
resource "aws_vpc_peering_connection" "Shared_and_Production_VPC_Peering" {
  peer_owner_id = var.peer_owner_id
  peer_vpc_id   = aws_vpc.Shared_VPC.id #VPC Accepter; server
  vpc_id        = aws_vpc.Production_VPC.id #VPC Requester; client
  auto_accept   = true

  tags = {
    Name = "VPC Peering between Shared and Production VPCs"
  }
}

#Shared-and-Dev VPC Peering
resource "aws_vpc_peering_connection" "Shared_and_Dev_VPC_Peering" {
  peer_owner_id = var.peer_owner_id
  peer_vpc_id   = aws_vpc.Shared_VPC.id #VPC Accepter; server
  vpc_id        = aws_vpc.Dev_VPC.id #VPC Requester; client
  auto_accept   = true

  tags = {
    Name = "VPC Peering between Shared and Dev VPCs"
  }
}

#Transit and Production VPC Peering
resource "aws_vpc_peering_connection" "Transit_and_Production_VPC_Peering" {
  peer_owner_id = var.peer_owner_id
  peer_vpc_id   = aws_vpc.Transit_VPC.id #VPC Accepter; server
  vpc_id        = aws_vpc.Production_VPC.id #VPC Requester; client
  auto_accept   = true

  tags = {
    Name = "VPC Peering between Transit and Production VPCs"
  }
}

#Transit and Shared VPC Peering
resource "aws_vpc_peering_connection" "Transit_and_Shared_VPC_Peering" {
  peer_owner_id = var.peer_owner_id
  peer_vpc_id   = aws_vpc.Transit_VPC.id #VPC Accepter; server
  vpc_id        = aws_vpc.Shared_VPC.id #VPC Requester; client
  auto_accept   = true

  tags = {
    Name = "VPC Peering between Transit and Shared VPCs"
  }
}

#Transit and Dev VPC Peering
resource "aws_vpc_peering_connection" "Transit_and_Dev_VPC_Peering" {
  peer_owner_id = var.peer_owner_id
  peer_vpc_id   = aws_vpc.Transit_VPC.id #VPC Accepter; server
  vpc_id        = aws_vpc.Dev_VPC.id #VPC Requester; client
  auto_accept   = true

  tags = {
    Name = "VPC Peering between Transit and Dev VPCs"
  }
}
