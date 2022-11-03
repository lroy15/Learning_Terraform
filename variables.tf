variable "sg_rules" {
  type = list(object({
    to_port     = string
    from_port   = string
    cidr_blocks = list(string)
    protocol    = string
  }))
  default = [
    {
      to_port     = 0
      from_port   = 0
      protocol    = "-1"
      cidr_blocks = ["10.0.0.0/16"]
    },
    {
      to_port     = 0
      from_port   = 0
      protocol    = "-1"
      cidr_blocks = ["10.200.0.0/16"]
    },
    {
      to_port     = 22
      from_port   = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      to_port     = 6443
      from_port   = 6443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      to_port     = 443
      from_port   = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      to_port     = 0
      from_port   = 0
      protocol    = "icmp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}


variable "ipaddrs" {
    type = list(string)
    default = ["10.0.1.10","10.0.1.11","10.0.1.12"]
}


variable "kuber_instances" {
    type = list(object({
    image-id     = string
    key-name    = string
    instance-type    = string
    private-ip-address = string
    user-data = string
    block-device-mappings = object({
        DeviceName = string
        Ebs = object({
            VolumeSize = number
        })
        NoDevice = string
    })
  }))
  default = [
    {
        image-id     = "ami-01d08089481510ba2"
        key-name    = "kubernetes"
        instance-type    = "t3.micro"
        private-ip-address = "10.0.1.10"
        user-data = "name=controller-0"
        block-device-mappings = {
            DeviceName = "/dev/sda1"
            Ebs = {
                VolumeSize = 50
            }
        NoDevice = ""
        }
    }
  ]
}