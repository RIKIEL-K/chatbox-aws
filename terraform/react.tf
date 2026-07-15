
resource "aws_ecr_repository" "react" {
  name                 = "${var.project_name}-react"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "${var.project_name}-react"
    Environment = var.environment
  }
}

resource "aws_security_group" "ecs_react" {
  name        = "${var.project_name}-ecs-react-sg"
  description = "Trafic React port 80 depuis ALB uniquement"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description     = "HTTP depuis ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-ecs-react-sg"
    Environment = var.environment
  }
}



resource "aws_lb_target_group" "react" {
  name        = "${var.project_name}-react-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id
  target_type = "ip"

  health_check {
    path                = "/health"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 10
    interval            = 30
    matcher             = "200"
  }

  tags = {
    Name        = "${var.project_name}-react-tg"
    Environment = var.environment
  }
}


resource "aws_lb_listener" "react" {
  load_balancer_arn = aws_lb.streamlit.arn
  port              = 3000
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.react.arn
  }
}



resource "aws_ecs_task_definition" "react" {
  family                   = "${var.project_name}-react"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution.arn

  container_definitions = jsonencode([{
    name  = "react"
    image = "${aws_ecr_repository.react.repository_url}:latest"

    portMappings = [{
      containerPort = 80
      protocol      = "tcp"
    }]

    environment = [
      {
        name  = "API_GATEWAY_URL"
        value = aws_api_gateway_stage.dev.invoke_url
      }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/${var.project_name}-react"
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "react"
      }
    }

    essential = true
  }])

  tags = {
    Name        = "${var.project_name}-react-task"
    Environment = var.environment
  }
}



resource "aws_cloudwatch_log_group" "ecs_react" {
  name              = "/ecs/${var.project_name}-react"
  retention_in_days = 14

  tags = {
    Name        = "${var.project_name}-react-logs"
    Environment = var.environment
  }
}



resource "aws_ecs_service" "react" {
  name            = "${var.project_name}-react"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.react.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [tolist(data.aws_subnets.default.ids)[0]]
    security_groups  = [aws_security_group.ecs_react.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.react.arn
    container_name   = "react"
    container_port   = 80
  }

  depends_on = [
    aws_lb_listener.react,
    aws_cloudwatch_log_group.ecs_react
  ]

  tags = {
    Name        = "${var.project_name}-react-svc"
    Environment = var.environment
  }
}

# ─── Outputs ───

output "react_url" {
  description = "URL de l'application React (ALB port 3000)"
  value       = "http://${aws_lb.streamlit.dns_name}:3000"
}

output "react_ecr_url" {
  description = "URL du dépôt ECR pour l'image React"
  value       = aws_ecr_repository.react.repository_url
}
