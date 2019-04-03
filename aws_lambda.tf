data "archive_file" "chromecrawler_lambda" {
  type        = "zip"
  output_path = "${path.module}/lambda/chromecrawler.zip"
  source_dir  = "${path.module}/lambda/chromecrawler"
}

resource "aws_lambda_function" "chromecrawler_lambda" {
  count = "${length(keys(var.api_slug_to_file))}"
  description = "Webdriver with Chromium in lambda"
  role        = "${aws_iam_role.this.arn}"
  runtime     = "nodejs8.10"

  filename         = "${data.archive_file.chromecrawler_lambda.output_path}"
  source_code_hash = "${data.archive_file.chromecrawler_lambda.output_base64sha256}"

  function_name = "chromecrawler_${var.environment}_${element(keys(var.api_slug_to_file), count.index)}_tf"
  handler       = "index.handler"

  timeout     = "29"
  memory_size = "2048"
  publish     = true

  environment {
    variables {
      BASE64_SCRIPT = "${base64encode(file(element(values(var.api_slug_to_file), count.index)))}"
    }
  }
}