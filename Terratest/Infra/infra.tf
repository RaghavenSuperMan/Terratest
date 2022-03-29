provider "aws" {
  profile = "dce"
  region  = "us-east-1"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.50.0"
  name    = "dev-works"
  cidr    = "21.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["21.0.1.0/24", "21.0.2.0/24"]
  public_subnets  = ["21.0.3.0/24", "21.0.4.0/24"]

  enable_nat_gateway = true
  enable_dns_hostnames = true
  enable_dns_support   = true
}


module "alb_http_80_sg" {
  source = "terraform-aws-modules/security-group/aws//modules/http-80"
  version = "4.2.0"
  name        = "80-sg"
  description = "Security group with tcp 80 ports open for internal ips (IPv4 CIDR), egress ports are all world open"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  #ingress_cidr_blocks = var.internal_ips
}

resource "aws_lb" "lambda-example" {
  name               = "test-lambda-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [module.alb_http_80_sg.security_group_id]
  subnets            = module.vpc.public_subnets
}
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.lambda-example.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lambda-example.arn
  }
}

resource "aws_lambda_permission" "with_lb" {
  statement_id  = "AllowExecutionFromlb"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.test_lambda.arn
  principal     = "elasticloadbalancing.amazonaws.com"
  source_arn    = aws_lb_target_group.lambda-example.arn
}


resource "aws_lb_target_group" "lambda-example" {
  name        = "lambda-tg"
  target_type = "lambda"
}

# resource "aws_lb_listener_rule" "static" {
#   listener_arn = "${aws_lb_listener.http.arn}"
#   priority     = 100

#   action {
#     type             = "forward"
#     target_group_arn = "${aws_lb_target_group.lambda-example.arn}"
#   }

#   condition {
#     field  = "path-pattern"
#     values = ["/static/*"]
#   }
# }

resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

data "aws_iam_policy" "adminaccess" {
  arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_role_policy_attachment" "sto-readonly-role-policy-attach" {
  role       = "${aws_iam_role.iam_for_lambda.name}"
  policy_arn = "${data.aws_iam_policy.adminaccess.arn}"
}

resource "aws_lambda_function" "test_lambda" {
  filename      = "raghaven_super_man.zip"
  function_name = "raghaven_super_man"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "raghaven_super_man.lambda_handler"
  source_code_hash = filebase64sha256("raghaven_super_man.zip")
  runtime = "python3.8"
}

resource "aws_lb_target_group_attachment" "test" {
  target_group_arn = aws_lb_target_group.lambda-example.arn
  target_id        = aws_lambda_function.test_lambda.arn
  depends_on       = [aws_lambda_permission.with_lb]
}

module "step_function" {
  source     = "terraform-aws-modules/step-functions/aws"
  version    = "0.1.0"
  name       = "raghav-pipeline"
  definition = <<EOF
        {
        "Comment": "Dummy STep function. It will be replaced in deployment",
        "StartAt": "Hello",
        "States": {
            "Hello": {
            "Type": "Pass",
            "Result": "Hello",
            "Next": "World"
            },
            "World": {
            "Type": "Pass",
            "Result": "World",
            "End": true
            }
        }
        }
        EOF
  # type = "STANDARD"
}