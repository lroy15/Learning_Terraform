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


variable ipaddrs {
    type = list(string)
    default = ["10.0.1.10","10.0.1.11","10.0.1.12"]
}