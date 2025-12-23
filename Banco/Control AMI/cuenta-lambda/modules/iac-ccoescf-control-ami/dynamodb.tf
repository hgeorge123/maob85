resource "aws_dynamodb_table" "centralized_dynamo_db_table" {
  name = "ami-control-table"
  hash_key = "allow_type"
  range_key = "allow_value"
  
  read_capacity  = 1
  write_capacity = 1

  attribute {
    name = "allow_type"
    type = "S"
  }

  
  attribute {
    name = "allow_value"
    type = "S"
  }

  #attribute {
  #  name = "account"
  #  type = "S"
  #}

  #global_secondary_index {
  #  name = "allow_value_on_account"
  #  hash_key = "allow_value"
  #  range_key = "account"
  #  projection_type = "ALL"
  #  read_capacity  = 1
  #  write_capacity = 1
  #}

  tags = var.mandatory_tags

}

resource "aws_dynamodb_table_item" "dynamodb_item" {
  count = length(var.dynamodb_items)

  table_name = aws_dynamodb_table.centralized_dynamo_db_table.name
  hash_key   = aws_dynamodb_table.centralized_dynamo_db_table.hash_key
  range_key    = aws_dynamodb_table.centralized_dynamo_db_table.range_key

  item = <<ITEM
    {
      "allow_type": {"S": "${var.dynamodb_items[count.index].allow_type}"},
      "allow_value": {"S": "${var.dynamodb_items[count.index].allow_value}"},
      "account": {"S": "${var.dynamodb_items[count.index].account}"}
    }
    ITEM
}