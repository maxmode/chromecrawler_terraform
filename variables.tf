variable "api_slug_to_file" {
  type = "map"
}

variable "environment" {}
variable "api_stage" {
  default = "v"
}

output "base_url" {
  value = "${aws_api_gateway_deployment.v1.invoke_url}"
}
