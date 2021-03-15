# variables.tf

variable "block_device_mappings" {
  type = any

  default = [
    {
      device_name = "/dev/sda1"
      volume_size           = "60"
      delete_on_termination = "true"
      volume_type           = "gp2"
      encrypted             = "true"

    },
    {
      device_name = "/dev/sdb"
      volume_size           = "60"
      delete_on_termination = "true"
      volume_type           = "gp2"
      encrypted             = "true"

    },
  ]
}
