
# IAMADMIN USER CREDENTIALS
variable "access_key" {
  type    = string
  default = ""
}

variable "secret_key" {
  type    = string
  default = ""
}

variable "region" {
  type    = string
  default = "eu-west-2"
}

variable "peer_owner_id" {
  type    = string
  default = ""
}

variable "key_name" {
  type    = string
  default = ""
}

#VPC CIDRs
variable "All_VPCs" {
  type = map(any)
  default = {
    Management_VPC = {
      ip = "10.0.0.0/24"
      instance_tenancy = "default"
    }
    Production_VPC = {
      ip = "10.0.1.0/24"
      instance_tenancy = "default"
    }
    Shared_VPC = {
      ip = "10.0.2.0/24"
      instance_tenancy = "default"
    }
    Dev_VPC = {
      ip = "10.0.3.0/24"
      instance_tenancy = "default"
    }
    Transit_VPC = {
      ip = "10.0.4.0/23"
      instance_tenancy = "default"
      description = "Transit_VPC"
    }
  }
}


#Subnet CIDRs
variable "Subnets" {
  type = map(string)

  default = {
    "Management_Subnet" = "10.0.0.0/25"
    "Production_Subnet" = "10.0.1.0/25"
    "Shared_Subnet" = "10.0.2.0/25"
    "Dev_Subnet" = "10.0.3.0/25"
    "Transit_Management_Subnet" = "10.0.4.0/26"
  }
}

variable "Transit_Private_Public_Subnets" {
  type = map(any)
  default = {
    Transit_Private_Subnet = {
      ip = "10.0.4.64/26"
      az = "eu-west-2b"
    }
    Transit_Public_Subnet = {
      ip = "10.0.4.128/26"
      az = "eu-west-2c"
    }
  }

}

#EC2 Linux AMI
variable "Amazon_Linux" {
  type    = string
  default = "ami-06672d07f62285d1d"
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "availability_zone" {
  type    = list(string)
  default = [
    "eu-west-2a",
    "eu-west-2b",
    "eu-west-2c"
  ]
}