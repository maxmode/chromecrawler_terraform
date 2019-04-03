data "aws_iam_policy_document" "sts" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type = "Service"

      identifiers = [
        "lambda.amazonaws.com",
      ]
    }
  }
}

data "aws_iam_policy_document" "this" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents",
      "logs:GetLogEvents",
      "logs:FilterLogEvents",
    ]

    resources = [
      "arn:aws:logs:*:*:*"
    ]
  }
}

resource "aws_iam_role_policy" "this" {
  name   = "chromecrawler_lambda_${var.environment}-basic-auth-policy"
  role   = "${aws_iam_role.this.id}"
  policy = "${data.aws_iam_policy_document.this.json}"
}

resource "aws_iam_role" "this" {
  name               = "${var.environment}-basic-auth-role"
  assume_role_policy = "${data.aws_iam_policy_document.sts.json}"
}
