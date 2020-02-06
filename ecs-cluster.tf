resource "aws_ecs_cluster" "ecs" {
  name = "cluster-${var.cluster-name}"
}

resource "aws_iam_role" "ecs_iam_role" {
  name = "iam-role-cluster-${var.cluster-name}"

  assume_role_policy = <<EOF
{
    "Version": "2008-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "ecs.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
}
EOF
}

resource "aws_iam_policy" "ec2_cluster_container_policy" {
  name        = "iam-policy-container-cluster-${var.cluster-name}"
  description = "Politicas para acesso a recursos AWS"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:Describe*",
          "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
          "elasticloadbalancing:DeregisterTargets",
          "elasticloadbalancing:Describe*",
          "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
          "elasticloadbalancing:RegisterTargets"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}
resource "aws_iam_policy_attachment" "ecs_iam_policy" {
  name       = "iam-policy-cluster-${var.cluster-name}"
  roles      = ["${aws_iam_role.ecs_iam_role.name}"]
  policy_arn = "${aws_iam_policy.ec2_cluster_container_policy.arn}"
}