variable "username" {
  default = "user1"
}

variable "sshkey" {
  default = "ssh-rsa ..."
}


variable "cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "azs" {
  type    = list(string)
  default = ["us-east-1a"]
}

variable "private_subnets" {
  type    = list(string)
  default = ["10.0.1.0/24"]
}

variable "public_subnets" {
  type    = list(string)
  default = ["10.0.2.0/24"]
}
