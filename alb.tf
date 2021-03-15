# ALB
resource "aws_alb" "tier_alb_internal" {
  name            = "test"
  internal        = "true"
  security_groups = [aws_security_group.custom_sg.id]
  subnets         = [
    aws_subnet.test_subnet_east_1a.id,
    aws_subnet.test_subnet_east_1b.id
  ]

  enable_deletion_protection = false
  idle_timeout = "60"

  tags = {
      Environment = "Test"
  }
}

# Listener 
resource "aws_alb_listener" "tier_listener" {
  load_balancer_arn = aws_alb.tier_alb_internal.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.tier_target_group.arn
    type             = "forward"
  }
}

# TargetGroup
resource "aws_alb_target_group" "tier_target_group" {
  name     = "test"
  port     = "80"                                                                         
  protocol = "HTTP"                                                                       
  vpc_id   = aws_vpc.test.id

  tags ={
    Environment = "Test"
  }
}