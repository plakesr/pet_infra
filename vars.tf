variable "AWS_REGION" {
  default = "us-east-1"
}

variable "app_name" {
  type = string
}

### vpc_vars ###
variable "cidr_block" {
  type    = string
}

variable "instance_tenancy" {
  type    = string
  default = "default"
}

###subent_vars###
variable "petclinic_subnet" {
  type = map(map(string))
}

###rt_vars##
variable "rt_cidr_block" {
    type = string
}

variable "public_subnets" {
    type = map(string)
}

##sg_vars##
variable "sg_conf" {
  type = map(map(string))
}
variable "type" {
  type    = string
  default = "ingress"
}

variable "protocol" {
  type    = string
  default = "-1"
}

variable "loadbalancer_list" {
  type = map(map(string))
}

#instance_vars
variable "instance_type" {
  default = "t2.micro"
}

variable "associate_public_ip_address" {
  type    = string
  default = "false"
}

##lb_vars##
variable "lb_list" {
  type = map(map(string))
}

variable "is_internal" {
  type    = string
  default = "true"
}

variable "loadbalancer_type" {
  type    = string
  default = "application"
}

variable "enable_deletion_protection" {
  type    = string
  default = "false"
}

variable "tg_conf" {
  type = map(map(string))
}

variable "tg_attachment_conf" {
  type = map(map(string))
}

##rds_vars##
variable "rds_az" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}