## step - 1 : CREATE SECURITY GROUP / EC2 / ALB / ASG

vim main.tf
-----------
# Configure the AWS provider
provider "aws" {
  region = "ap-south-1"
}

# Data source: query the list of availability zones
data "aws_availability_zones" "all" {}

# Create a Security Group for an EC2 instance
resource "aws_security_group" "instance" {
  name = "terraform-example-instance"
  
  ingress {
    from_port	  = "${var.server_port}"
    to_port		  = "${var.server_port}"
    protocol	  = "tcp"
    cidr_blocks	= ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Create a Security Group for an ELB
resource "aws_security_group" "elb" {
  name = "terraform-example-elb"
  vpc_id      = "vpc-your-vpc-id"
  description = "any comments to describe"
  
  ingress {
    from_port	  = 80
	  to_port		  = 80
	  protocol	  = "tcp"
	  cidr_blocks	= ["0.0.0.0/0"]
  }

  egress {
    from_port	  = 0
	  to_port		  = 0
	  protocol	  = "-1"
	  cidr_blocks	= ["0.0.0.0/0"]
  }
}

# Create a Launch Configuration
resource "aws_launch_configuration" "example" {
  image_id		    = "<your-ami-id>"
  instance_type   = "t2.micro"
  security_groups = ["${aws_security_group.instance.id}"]
  
  user_data = <<-EOF
              #!/bin/bash
              sudo yum install httpd -y
              sudo echo "<h1>webserver with ASG & ALB </h1> " >> /var/www/html/index.html
              sudo systemctl start httpd && systemctl enable httpd
              EOF
			  
  lifecycle {
    create_before_destroy = true
  }
}

# Create an Autoscaling Group
resource "aws_autoscaling_group" "example" {
  launch_configuration = "${aws_launch_configuration.example.id}"
  availability_zones   = ["${data.aws_availability_zones.all.names}"]
  
  load_balancers       = ["${aws_elb.example.name}"]
  health_check_type    = "ELB"
  
  min_size = 2
  max_size = 10
  
  tag {
    key                 = "Name"
    value               = "terraform-asg-example"
    propagate_at_launch = true
  }
}

# Create an ELB
resource "aws_elb" "example" {
  name               = "terraform-asg-example"
  availability_zones = ["${data.aws_availability_zones.all.names}"]
  security_groups    = ["${aws_security_group.elb.id}"]
  
  listener {
    lb_port           = 80
    lb_protocol       = "http"
    instance_port     = "${var.server_port}"
    instance_protocol = "http"
  }
  
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    target              = "HTTP:${var.server_port}/"
  }
}

### ------ file ends here

### step -2 : CREATE OUTPUT FILE

vim outputs.tf
--------------
# Output variable: DNS Name of ELB
output "elb_dns_name" {
  value = "${aws_elb.example.dns_name}"
}

### --- file ends here


### step - 3: CREATE VARIABLES

vim vars.tf
-----------
# Input variable: server port
variable "server_port" {
  description = "The port the server will use for HTTP requests"
  default = "8080"
}


#### WORKING INSTRUCTIONS ####
# terraform init
# Modify server port configuration.
# terraform plan -var 'server_port=8080'
# terraform apply -var 'server_port=8080'
# check it using - curl http://http://<elb_dns_name>/