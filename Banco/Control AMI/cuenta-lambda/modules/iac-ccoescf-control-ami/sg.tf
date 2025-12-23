resource "aws_security_group" "sg_lambda" {
  name        = "ami-checker-sg_lambda"
  description = "sg_lambda"
  vpc_id      = var.vpc_id
  tags        = var.mandatory_tags
}

resource "aws_security_group_rule" "sg_ingress_rules-sg_lambda" {
  count = length(var.sg_ingress_rules)

  type              = "ingress"
  from_port         = var.sg_ingress_rules[count.index].from_port
  to_port           = var.sg_ingress_rules[count.index].to_port
  protocol          = var.sg_ingress_rules[count.index].protocol
  cidr_blocks       = var.sg_ingress_rules[count.index].cidr_blocks
  security_group_id = aws_security_group.sg_lambda.id
}

resource "aws_security_group_rule" "sg_egress_rules-sg_lambda" {
  count = length(var.sg_egress_rules)

  type              = "egress"
  from_port         = var.sg_egress_rules[count.index].from_port
  to_port           = var.sg_egress_rules[count.index].to_port
  protocol          = var.sg_egress_rules[count.index].protocol
  cidr_blocks       = var.sg_egress_rules[count.index].cidr_blocks
  security_group_id = aws_security_group.sg_lambda.id
}