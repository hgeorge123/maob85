resource "aws_iam_policy" "policy" {

  name        = "image-builder-policy"
  path        = "/"
  description = "image-builder-policy"
  tags = merge(var.mandatory_tags, var.custom_tags)
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
          "Effect": "Allow",
          "Action": [
              "ec2:DescribeImages",
              "ec2:DescribeImageAttribute",
              "ec2:CreateNetworkInterface",
            "ec2:DescribeNetworkInterfaces",
            "ec2:DeleteNetworkInterface"
          ],
          "Resource": "*"
      },
      {
        "Action": [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "imagebuilder:UpdateImagePipeline",
          "imagebuilder:CreateImagePipeline",
          "imagebuilder:CreateImageRecipe",
          "imagebuilder:DeleteImageRecipe",
          "imagebuilder:GetImage",
          "imagebuilder:GetImagePipeline",
          "imagebuilder:GetImageRecipe",
          "imagebuilder:GetImageRecipePolicy",
          "imagebuilder:ListImageRecipes",
          "imagebuilder:ListImages",
          "imagebuilder:TagResource",
          "sns:Subscribe",
          "sns:Publish",
          "sns:GetTopicAttributes",
          "imagebuilder:ListComponentBuildVersions",
          "imagebuilder:ListImageScanFindingAggregations",
          "imagebuilder:GetComponent",
          "imagebuilder:ListImagePipelines",
          "imagebuilder:ListTagsForResource",
          "imagebuilder:ListDistributionConfigurations",
          "imagebuilder:ListImagePipelineImages",
          "imagebuilder:ListContainerRecipes",
          "imagebuilder:ListInfrastructureConfigurations",
          "imagebuilder:GetInfrastructureConfiguration",
          "imagebuilder:GetImagePolicy",
          "imagebuilder:ListWorkflowStepExecutions",
          "imagebuilder:GetWorkflowStepExecution",
          "imagebuilder:GetComponentPolicy",
          "imagebuilder:GetDistributionConfiguration",
          "imagebuilder:GetContainerRecipe",
          "imagebuilder:ListImagePackages",
          "imagebuilder:ListComponents",
          "imagebuilder:ListImageBuildVersions",
          "imagebuilder:ListWorkflowExecutions",
          "imagebuilder:GetWorkflowExecution",
          "imagebuilder:GetContainerRecipePolicy",
          "imagebuilder:ListImageScanFindings"
        ],
        "Effect": "Allow",
        "Resource": [
            "arn:aws:logs:${data.aws_region.current.region}:*:log-group:/aws/lambda/*",
            "arn:aws:imagebuilder:${data.aws_region.current.region}:*:image-recipe/*",
            "arn:aws:imagebuilder:${data.aws_region.current.region}:*:image-pipeline/*",
            "arn:aws:imagebuilder:${data.aws_region.current.region}:*:component/*",
            "arn:aws:imagebuilder:${data.aws_region.current.region}:*:distribution-configuration/*",
            "arn:aws:imagebuilder:${data.aws_region.current.region}:*:infrastructure-configuration/*",
            "arn:aws:sns:${data.aws_region.current.region}:*:*"
        ]
      }
    ]
  })
}