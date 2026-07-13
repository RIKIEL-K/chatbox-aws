# ─── ECR Repository ───

resource "aws_ecr_repository" "streamlit" {
  name                 = "${var.project_name}-streamlit"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "${var.project_name}-streamlit"
    Environment = var.environment
  }
}

# ─── ECS Cluster ───

resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name        = "${var.project_name}-cluster"
    Environment = var.environment
  }
}

# ─── IAM — Rôle d'exécution ECS (pull ECR + logs) ───

resource "aws_iam_role" "ecs_execution" {
  name = "${var.project_name}-ecs-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Name        = "${var.project_name}-ecs-exec-role"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ─── Security Groups ───

resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Trafic HTTP entrant vers ALB Streamlit"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "HTTP depuis Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-alb-sg"
    Environment = var.environment
  }
}

# Seul le trafic provenant de l'ALB peut atteindre Streamlit
resource "aws_security_group" "ecs" {
  name        = "${var.project_name}-ecs-sg"
  description = "Trafic Streamlit port 8501 depuis ALB uniquement"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description     = "Streamlit depuis ALB"
    from_port       = 8501
    to_port         = 8501
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
    Name        = "${var.project_name}-ecs-sg"
    Environment = var.environment
  }
}

# ─── Application Load Balancer ───

resource "aws_lb" "streamlit" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = data.aws_subnets.default.ids

  tags = {
    Name        = "${var.project_name}-alb"
    Environment = var.environment
  }
}

resource "aws_lb_target_group" "streamlit" {
  name        = "${var.project_name}-tg"
  port        = 8501
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id
  target_type = "ip"

  # Streamlit expose un endpoint de health check natif
  health_check {
    path                = "/_stcore/health"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 10
    interval            = 30
    matcher             = "200"
  }

  tags = {
    Name        = "${var.project_name}-tg"
    Environment = var.environment
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.streamlit.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.streamlit.arn
  }
}

# ─── ECS Task Definition (Fargate) ───

resource "aws_ecs_task_definition" "streamlit" {
  family                   = "${var.project_name}-streamlit"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution.arn

  container_definitions = jsonencode([{
    name  = "streamlit"
    image = "${aws_ecr_repository.streamlit.repository_url}:latest"

    portMappings = [{
      containerPort = 8501
      protocol      = "tcp"
    }]

    # L'URL API Gateway est injectée en variable d'env (zéro clé en dur)
    environment = [
      {
        name  = "API_GATEWAY_URL"
        value = "${aws_api_gateway_stage.dev.invoke_url}/chat"
      }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/${var.project_name}-streamlit"
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "streamlit"
      }
    }

    essential = true
  }])

  tags = {
    Name        = "${var.project_name}-streamlit-task"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.project_name}-streamlit"
  retention_in_days = 14

  tags = {
    Name        = "${var.project_name}-ecs-logs"
    Environment = var.environment
  }
}

# ─── ECS Service — 1 seule tâche, single-zone ───

resource "aws_ecs_service" "streamlit" {
  name            = "${var.project_name}-streamlit"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.streamlit.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  # Déploiement single-zone : un seul subnet par défaut
  network_configuration {
    subnets          = [tolist(data.aws_subnets.default.ids)[0]]
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.streamlit.arn
    container_name   = "streamlit"
    container_port   = 8501
  }

  depends_on = [
    aws_lb_listener.http,
    aws_cloudwatch_log_group.ecs
  ]

  tags = {
    Name        = "${var.project_name}-streamlit-svc"
    Environment = var.environment
  }
}
