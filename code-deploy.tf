resource "aws_codedeploy_app" "code_deploy_app" {
  count            = "${length(values(var.service-name))}"
  compute_platform = "ECS"
  name             = "${var.cluster-name}-${var.service-name["service-${count.index}"]}"
}

resource "aws_codedeploy_deployment_group" "example" {
  count                  = "${length(values(var.service-name))}"
  app_name               = "${aws_codedeploy_app.code_deploy_app.*.name[count.index]}"
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
  deployment_group_name  = "${var.service-name["service-${count.index}"]}"
  service_role_arn       = "${aws_iam_role.code_deploy_role.arn}"
  

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 2
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  ecs_service {
    cluster_name = "${aws_ecs_cluster.ecs.name}"
    service_name = "${aws_ecs_service.ecs-service.*.name[count.index]}"
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = ["${aws_alb_listener.alb_listener.arn}"]
      }

      target_group {
        name = "${aws_alb_target_group.tg-ecs-service-blue.*.name[count.index]}"
      }

      target_group {
        name = "${aws_alb_target_group.tg-ecs-service-green.*.name[count.index]}"
      }
    }
  }
}

resource "aws_iam_role" "code_deploy_role" {
  name = "role-code-deploy-${var.cluster-name}"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Principal": {
                "Service": "codedeploy.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        },
        {
            "Sid": "",
            "Effect": "Allow",
            "Principal": {
                "Service": "ecs-tasks.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "AWSCodeDeployRole" {
  policy_arn = "${aws_iam_policy.code_deploy_policy.arn}"
  role       = "${aws_iam_role.code_deploy_role.name}"
}

resource "aws_iam_policy" "code_deploy_policy" {
  name        = "policy-code-deploy-${var.cluster-name}"
  description = "Politicas para acesso a recursos AWS"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
        "Action": [
            "ecs:DescribeServices",
            "ecs:CreateTaskSet",
            "ecs:UpdateServicePrimaryTaskSet",
            "ecs:DeleteTaskSet",
            "elasticloadbalancing:DescribeTargetGroups",
            "elasticloadbalancing:DescribeListeners",
            "elasticloadbalancing:ModifyListener",
            "elasticloadbalancing:DescribeRules",
            "elasticloadbalancing:ModifyRule",
            "lambda:InvokeFunction",
            "cloudwatch:DescribeAlarms",
            "sns:Publish",
            "s3:GetObject",
            "s3:GetObjectMetadata",
            "s3:GetObjectVersion"
        ],
        "Resource": "*",
        "Effect": "Allow"
    },
    {
        "Action": [
            "iam:PassRole"
        ],
        "Effect": "Allow",
        "Resource": "*",
        "Condition": {
            "StringLike": {
                "iam:PassedToService": [
                    "ecs-tasks.amazonaws.com"
                ]
            }
        }
    },
    {
        "Effect": "Allow",
        "Action": [
            "s3:Get*",
            "s3:List*"
        ],
        "Resource": "*"
    }
  ]
}
EOF
}
