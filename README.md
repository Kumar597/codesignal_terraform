# codesignal_terraform
This terraform script provides a load balanced autoscale group tier of EC2 instances.
This script runs in terrform version 12 and above.

## Group Module:
The group module will provision VPC, Private Subnets, Route table, SecurityGroup, LaunchTemplate and AutoScalingGroup resources, ALB is supported. Also configured SNS topic and cloud watch metric alarms around LB and CPUUtilization.
