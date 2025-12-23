resource "aws_sns_topic" "builder" {
  name = "${var.ami_name}-image-builder-topic"
  tags = var.tags
}

resource "aws_sns_topic" "email" {
  name = "${var.ami_name}-image-builder-topic-email"
  tags = var.tags
}

resource "aws_sns_topic_subscription" "email" {
  for_each = toset(var.email_notifications)

  topic_arn = aws_sns_topic.email.arn
  protocol  = "email"
  endpoint  = each.value
}
