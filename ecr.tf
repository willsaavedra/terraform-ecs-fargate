resource "aws_ecr_repository" "ecr" {
  count                = "${length(values(var.service-name))}"
  name                 = "${var.cluster-name}-${var.service-name["service-${count.index}"]}"
}
