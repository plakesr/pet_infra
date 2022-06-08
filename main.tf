locals {
  common_tags = {
    env         = "poc"
    application = var.app_name
  }
}

data "aws_ami" "petclinic-ui" {
  owners = ["self"]

  filter {
    name   = "name"
    values = ["petclinic-ui-ami"]
  }
}

data "aws_ami" "petclinic-api" {
  owners = ["self"]

  filter {
    name   = "name"
    values = ["petclinic-ui-ami"]
  }
}

resource "aws_vpc" "vpc" {
  cidr_block       = var.cidr_block
  instance_tenancy = var.instance_tenancy
  tags             = local.common_tags 
}

resource "aws_subnet" "subnet" {
  for_each                = var.petclinic_subnet
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = each.value.cidr_block
  map_public_ip_on_launch = each.value.map_public_ip_on_launch
  availability_zone       = each.value.availability_zone
  tags                    = local.common_tags
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags   = local.common_tags
}

resource "aws_route_table" "r_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = var.rt_cidr_block
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = local.common_tags
}

resource "aws_route_table_association" "rt_associate" {
  for_each = var.public_subnets  
  subnet_id      = aws_subnet.subnet[each.key].id
  route_table_id = aws_route_table.r_table.id
}

resource "aws_security_group" "security_groups" {
  for_each = var.sg_conf
  name        = "${var.app_name}-${each.value.sg_name}-${each.value.sg_for}-sg"
  vpc_id      = aws_vpc.vpc.id
  tags        = local.common_tags
}

resource "aws_security_group_rule" "sg_rule" {
  for_each = var.sg_conf
  type                     = var.type
  from_port                = each.value.open_port
  to_port                  = each.value.open_port
  protocol                 = var.protocol
  security_group_id        = aws_security_group.security_groups[each.key].id
  source_security_group_id = aws_security_group.security_groups[each.value.source_sg_id].id
}

resource "aws_security_group_rule" "lb_sg_rule" {
  for_each = var.loadbalancer_list
  type                     = var.type
  from_port                = 80
  to_port                  = 80
  security_group_id        = aws_security_group.security_groups[each.value.lb_sg_name].id
  cidr_blocks       = ["0.0.0.0/0"]
  protocol                 = var.protocol
}

resource "aws_security_group_rule" "sg_egress_rule" {
  for_each = var.sg_conf
  type                     = "egress"
  from_port                = each.value.open_port
  to_port                  = each.value.open_port
  protocol                 = var.protocol
  security_group_id        = aws_security_group.security_groups[each.key].id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_instance" "ec2" {
  for_each =  {
    ui    = { AMI_id = data.aws_ami.petclinic-ui.id, sg_name = "ui", private_subnet = "pvt_sub1" }
    rest  = { AMI_id = data.aws_ami.petclinic-ui.id, sg_name = "rest", private_subnet = "pvt_sub1" }
    ui2   = { AMI_id = data.aws_ami.petclinic-ui.id, sg_name = "ui", private_subnet = "pvt_sub1" }
    rest2 = { AMI_id = data.aws_ami.petclinic-ui.id, sg_name = "rest", private_subnet = "pvt_sub1" }
  }
  ami                         = each.value.AMI_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.subnet[each.value.private_subnet].id
  associate_public_ip_address = var.associate_public_ip_address
  vpc_security_group_ids      = [aws_security_group.security_groups[each.value.sg_name].id]
}

resource "aws_lb" "loadbalancer" {
  for_each = var.lb_list
  name                       = "alb-${each.key}"
  internal                   = "false"
  load_balancer_type         = var.loadbalancer_type
  security_groups            = [aws_security_group.security_groups[each.value.lb_sg_name].id]
  subnets                    = [aws_subnet.subnet["pub_sub1"].id, aws_subnet.subnet["pub_sub2"].id]
  enable_deletion_protection = var.enable_deletion_protection

  tags = local.common_tags
}

resource "aws_lb_target_group" "target_group" {
  for_each = var.tg_conf
  name        = "tg-${each.key}"
  port        = each.value.tg_port
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.vpc.id
  health_check {
    enabled = true
    path    = "/"
    port    = each.value.health_check_port
  }
}

resource "aws_lb_target_group_attachment" "target_group_attachment" {
  for_each = var.tg_attachment_conf
  target_group_arn = aws_lb_target_group.target_group[each.value.tg_name].arn
  target_id        = aws_instance.ec2[each.key].id
  port             = each.value.health_check_port
}

resource "aws_lb_listener" "listner" {
  for_each = var.lb_list
  load_balancer_arn = aws_lb.loadbalancer[each.key].arn
  port              = "80"
  protocol          = "HTTP"
  certificate_arn   = null

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group[each.key].arn
  }
}

resource "aws_rds_cluster" "postgresql" {
  cluster_identifier      = "db-pg"
  source_region           = var.AWS_REGION
  engine                  = "aurora-postgresql"
  engine_version          = "10.14"
  engine_mode             = "serverless"
  deletion_protection     = false
  availability_zones      = var.rds_az
  database_name           = "petclinic"
  db_subnet_group_name    = aws_db_subnet_group.rds_subnet_group.name
  master_username         = "postgres"
  master_password         = "CarTruckR0b0t"
  backup_retention_period = 5
  preferred_backup_window = "07:00-09:00"
  vpc_security_group_ids  = [aws_security_group.security_groups["db"].id]
  enable_http_endpoint    = true
  skip_final_snapshot     = true

  scaling_configuration {
    auto_pause               = true
    max_capacity             = 2
    min_capacity             = 2
    seconds_until_auto_pause = 300
    timeout_action           = "ForceApplyCapacityChange"
  }
  tags = local.common_tags
}

resource "aws_db_subnet_group" "rds_subnet_group" {
  subnet_ids = [aws_subnet.subnet["pvt_sub1"].id, aws_subnet.subnet["pvt_sub2"].id]
  tags       = local.common_tags
}

resource "aws_route53_zone" "route53_zone" {
  name = "pet-clinic.io"
  tags = local.common_tags
}

resource "aws_route53_record" "route53" {
  for_each = {
    ui   = { sub_domain = "www", record_value = aws_lb.loadbalancer["ui"].dns_name }
    rest = { sub_domain = "api", record_value = aws_lb.loadbalancer["rest"].dns_name }
    db   = { sub_domain = "db", record_value = aws_rds_cluster.postgresql.endpoint }
  }
  zone_id = aws_route53_zone.route53_zone.id
  name    = "${each.value.sub_domain}.pet-clinic.io"
  type    = "CNAME"
  ttl     = 600
  records = [each.value.record_value]
}
