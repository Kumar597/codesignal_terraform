# SNS topic and CloudWatch Metric Alarms
resource "aws_sns_topic" "test" {
  name = "test"
}

resource "aws_sns_topic_policy" "test" {
  arn    = aws_sns_topic.test.arn
  policy = data.aws_iam_policy_document.test.json
}

data "aws_iam_policy_document" "test" {
  statement {
    actions = [
      "SNS:Publish",
    ]

    resources = [
      aws_sns_topic.test.arn,
    ]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

# Metric for ALB
resource "aws_cloudwatch_metric_alarm" "alb" {
  alarm_name                = "webserver-alb"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "2"
  metric_name               = "HTTPCode_ELB_5XX_Count"
  namespace                 = "AWS/ApplicationELB"
  period                    = "120"
  statistic                 = "Maximum"
  threshold                 = "10"
  alarm_actions             = [aws_sns_topic.test.arn]
  ok_actions                = [aws_sns_topic.test.arn]
  dimensions                =  {
    LoadBalancer = aws_alb.tier_alb_internal.arn_suffix
    TargetGroup  = aws_alb_target_group.tier_target_group.arn_suffix
  }
  
  tags = {
    Environment = "Test"
  }
}

# Metric for CPUUtilization on EC2
resource "aws_cloudwatch_metric_alarm" "cpu" {
  alarm_name                = "webserver-usage"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "2"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = "120"
  statistic                 = "Average"
  threshold                 = "80"
  alarm_description         = "This metric monitors ec2 cpu utilization"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.tier.name
  }
  
  tags = {
    Environment = "Test"
  }
}