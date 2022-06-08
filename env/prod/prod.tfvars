app_name = "pet_clinic"

##vpc_vars##
cidr_block = "10.0.0.0/16"

##subent_vars##
petclinic_subnet = {
    "pub_sub1" = { cidr_block = "10.0.1.0/24", map_public_ip_on_launch = "true", availability_zone = "us-east-1a" }
    "pub_sub2" = { cidr_block = "10.0.2.0/24", map_public_ip_on_launch = "true", availability_zone = "us-east-1b" }
    "pvt_sub1" = { cidr_block = "10.0.3.0/24", map_public_ip_on_launch = "false", availability_zone = "us-east-1a" }
    "pvt_sub2" = { cidr_block = "10.0.4.0/24", map_public_ip_on_launch = "false", availability_zone = "us-east-1b" }

  }

##route_table##
rt_cidr_block = "0.0.0.0/0"

public_subnets = { 
    "pub_sub1" : ""
    "pub_sub2" : ""
    }

##sg_vars##
sg_conf = {
    ui      = { sg_name = "ui", sg_for = "ec2", open_port = 80, source_sg_id = "ui-lb" }
    rest    = { sg_name = "rest", sg_for = "ec2", open_port = 9096, source_sg_id = "rest-lb" }
    db      = { sg_name = "db", sg_for = "db", open_port = 5432, source_sg_id = "rest" }
    ui-lb   = { sg_name = "ui", sg_for = "loadbalancer", open_port = 80, source_sg_id = "ui" }
    rest-lb = { sg_name = "rest", sg_for = "loadbalancer", open_port = 80, source_sg_id = "rest" }
  }

loadbalancer_list = {
    ui   = { lb_sg_name = "ui-lb" }
    rest = { lb_sg_name = "rest-lb" }
  }

  ##lb_vars##
lb_list = {
    ui   = { lb_sg_name = "ui-lb", public_subnet = "pub_sub1" }
    rest = { lb_sg_name = "rest-lb", public_subnet = "pub_sub2" }
  }

  tg_conf = {
    ui   = { tg_port = 80, health_check_port = 80 }
    rest = { tg_port = 9966, health_check_port = 9966 }
  }

  tg_attachment_conf = {
    ui    = { tg_name = "ui", tg_port = 80, health_check_port = 80 }
    ui2   = { tg_name = "ui", tg_port = 80, health_check_port = 80 }
    rest  = { tg_name = "rest", tg_port = 9966, health_check_port = 9966 }
    rest2 = { tg_name = "rest", tg_port = 9966, health_check_port = 9966 }
  }
