resource "aws_secretsmanager_secret" "secret_manager" {
  count = "${length(values(var.service-name))}"
  name  = "${var.cluster-name}-ms-${var.service-name["service-${count.index}"]}"
}

variable "secret_example" {
  default = {
    key1 = "value1"
    key2 = "value2"
  }

  type = "map"
}

resource "aws_secretsmanager_secret_version" "secret_manager_example" {
  count         = "${length(values(var.service-name))}"
  secret_id     = "${aws_secretsmanager_secret.secret_manager.*.id[count.index]}"
  secret_string = "${jsonencode(var.secret_example)}"
}
