module "alb" {
  source = "terraform-aws-modules/alb/aws"

  # Truncated for brevity ...

  listeners = {
    https = {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = "arn:aws:iam::123456789012:server-certificate/test_cert-123456789012"

      forward = {
        target_group_key = "instance"
      }

      rules = {
        redirect = {
          priority = 5000
          actions = [{
            type        = "redirect"
            status_code = "HTTP_302"
            host        = "www.youtube.com"
            path        = "/watch"
            query       = "v=dQw4w9WgXcQ"
            protocol    = "HTTPS"
          }]

          conditions = [{
            path_pattern = {
              values = ["/onboarding", "/docs"]
            }
          }]
        }

        cognito = {
          priority = 2
          actions = [
            {
              type                = "authenticate-cognito"
              user_pool_arn       = "arn:aws:cognito-idp::123456789012:userpool/test-pool"
              user_pool_client_id = "6oRmFiS0JHk="
              user_pool_domain    = "test-domain-com"
            },
            {
              type             = "forward"
              target_group_key = "instance"
            }
          ]

          conditions = [{
            path_pattern = {
              values = ["/protected-route", "private/*"]
            }
          }]
        }
      }
    }
  }

  target_groups = {
    instance = {
      name_prefix = "default"
      protocol    = "HTTPS"
      port        = 443
      target_type = "instance"
    }
  }
}