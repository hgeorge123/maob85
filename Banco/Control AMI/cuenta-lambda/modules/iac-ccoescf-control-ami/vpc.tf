
/* resource "aws_vpc_endpoint" "dynamodb_vpc_endpoint" {
  vpc_id       = var.vpc_id
  service_name = "com.amazonaws.${data.aws_region.current.name}.dynamodb"
  tags = var.mandatory_tags
  route_table_ids = [data.aws_vpc.current.main_route_table_id]
}

resource "aws_vpc_endpoint" "ec2_vpc_endpoint" {
  vpc_endpoint_type = "Interface"
  vpc_id       = var.vpc_id
  service_name = "com.amazonaws.${data.aws_region.current.name}.ec2"
  tags = var.mandatory_tags
  subnet_ids = var.subnet_ids
  security_group_ids = [aws_security_group.sg_lambda.id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "sts_vpc_endpoint" {
  vpc_endpoint_type = "Interface"
  vpc_id       = var.vpc_id
  service_name = "com.amazonaws.${data.aws_region.current.name}.sts"
  tags = var.mandatory_tags
  subnet_ids = var.subnet_ids
  security_group_ids = [aws_security_group.sg_lambda.id]
  private_dns_enabled = true
} 
*/