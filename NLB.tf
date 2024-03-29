module "nlb" {
  source = "terraform-aws-modules/alb/aws"

  name               = "my-nlb"
  load_balancer_type = "network"
  vpc_id             = "vpc-abcde012"
  subnets            = ["subnet-abcde012", "subnet-bcde012a"]

  # Security Group
  enforce_security_group_inbound_rules_on_private_link_traffic = "on"
  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 82
      ip_protocol = "tcp"
      description = "HTTP web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
    all_https = {
      from_port   = 443
      to_port     = 445
      ip_protocol = "tcp"
      description = "HTTPS web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = "10.0.0.0/16"
    }
  }

  access_logs = {
    bucket = "my-nlb-logs"
  }

  listeners = {
    ex-tcp-udp = {
      port     = 81
      protocol = "TCP_UDP"
      forward = {
        target_group_key = "ex-target"
      }
    }

    ex-udp = {
      port     = 82
      protocol = "UDP"
      forward = {
        target_group_key = "ex-target"
      }
    }

    ex-tcp = {
      port     = 83
      protocol = "TCP"
      forward = {
        target_group_key = "ex-target"
      }
    }

    ex-tls = {
      port            = 84
      protocol        = "TLS"
      certificate_arn = "arn:aws:iam::123456789012:server-certificate/test_cert-123456789012"
      forward = {
        target_group_key = "ex-target"
      }
    }
  }

  target_groups = {
    ex-target = {
      name_prefix = "pref-"
      protocol    = "TCP"
      port        = 80
      target_type = "ip"
    }
  }

  tags = {
    Environment = "Development"
    Project     = "Example"
  }
}