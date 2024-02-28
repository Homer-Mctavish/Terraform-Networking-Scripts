module "alb" {
  source = "terraform-aws-modules/alb/aws"

  # Truncated for brevity ...

  listeners = {
    ex-http-https-redirect = {
      port     = 80
      protocol = "HTTP"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
    ex-cognito = {
      port            = 444
      protocol        = "HTTPS"
      certificate_arn = "arn:aws:iam::123456789012:server-certificate/test_cert-123456789012"

      authenticate_cognito = {
        authentication_request_extra_params = {
          display = "page"
          prompt  = "login"
        }
        on_unauthenticated_request = "authenticate"
        session_cookie_name        = "session-${local.name}"
        session_timeout            = 3600
        user_pool_arn              = "arn:aws:cognito-idp:us-west-2:123456789012:userpool/us-west-2_abcdefghi"
        user_pool_client_id        = "us-west-2_fak3p001B"
        user_pool_domain           = "https://fak3p001B.auth.us-west-2.amazoncognito.com"
      }

      forward = {
        target_group_key = "ex-instance"
      }

      rules = {
        ex-oidc = {
          priority = 2

          actions = [
            {
              type = "authenticate-oidc"
              authentication_request_extra_params = {
                display = "page"
                prompt  = "login"
              }
              authorization_endpoint = "https://foobar.com/auth"
              client_id              = "client_id"
              client_secret          = "client_secret"
              issuer                 = "https://foobar.com"
              token_endpoint         = "https://foobar.com/token"
              user_info_endpoint     = "https://foobar.com/user_info"
            },
            {
              type             = "forward"
              target_group_key = "ex-instance"
            }
          ]
        }
      }
    }
  }
}