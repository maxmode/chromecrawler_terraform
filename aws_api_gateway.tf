resource "aws_api_gateway_rest_api" "chromecrawler_api" {
  name        = "Chromecrawler Api ${var.environment}"
  binary_media_types = [
    "*/*"
  ]
}

resource "aws_api_gateway_resource" "proxy" {
  count = "${length(keys(var.api_slug_to_file))}"
  rest_api_id = "${aws_api_gateway_rest_api.chromecrawler_api.id}"
  parent_id   = "${aws_api_gateway_rest_api.chromecrawler_api.root_resource_id}"
  path_part   = "${element(keys(var.api_slug_to_file), count.index)}"
}

resource "aws_api_gateway_method" "proxy" {
  count = "${length(keys(var.api_slug_to_file))}"
  rest_api_id   = "${aws_api_gateway_rest_api.chromecrawler_api.id}"
  resource_id   = "${element(aws_api_gateway_resource.proxy.*.id, count.index)}"
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda" {
  count = "${length(keys(var.api_slug_to_file))}"
  rest_api_id = "${aws_api_gateway_rest_api.chromecrawler_api.id}"

  resource_id = "${element(aws_api_gateway_method.proxy.*.resource_id, count.index)}"
  http_method = "${element(aws_api_gateway_method.proxy.*.http_method, count.index)}"

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${element(aws_lambda_function.chromecrawler_lambda.*.invoke_arn, count.index)}"
}

resource "aws_api_gateway_deployment" "v1" {
  depends_on = [
    "aws_api_gateway_integration.lambda",
  ]

  rest_api_id = "${aws_api_gateway_rest_api.chromecrawler_api.id}"
  stage_name  = "${var.api_stage}"
}

resource "aws_lambda_permission" "apigw" {
  count = "${length(keys(var.api_slug_to_file))}"
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "${element(aws_lambda_function.chromecrawler_lambda.*.arn, count.index)}"
  principal     = "apigateway.amazonaws.com"

  # The /*/* portion grants access from any method on any resource
  # within the API Gateway "REST API".
  source_arn = "${aws_api_gateway_deployment.v1.execution_arn}/*/*"
}