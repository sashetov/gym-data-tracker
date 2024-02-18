provider "aws" {
  profile = "default"
  region = "us-west-2" # Set your desired AWS region
}

data "aws_route53_zone" "selected" {
  name         = "vassilevski.com." # Ensure the domain name ends with a dot
  private_zone = false          # Set to true if you're querying a private hosted zone
}

resource "aws_security_group" "flask_security_group" {
  name_prefix = "flask-sg-"
  vpc_id = "vpc-1fa41b7b"
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_key_pair" "my_key_pair" {
  key_name   = "mykeypair"
  public_key = file("./mykeypair.pub")
}
resource "aws_instance" "flask_server" {
  ami           = "ami-0d442a425e2e0a743"
  instance_type = "t2.micro"
  key_name      = aws_key_pair.my_key_pair.key_name
  security_groups    = [aws_security_group.flask_security_group.id]
  subnet_id          = "subnet-f58f3491"
  associate_public_ip_address = true
  user_data = templatefile("${path.module}/user_data_script.tpl", {
    htpasswd_user     = var.htpasswd_user,
    htpasswd_password = var.htpasswd_password
  })
}
resource "aws_route53_record" "example" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "backenddemo.vassilevski.com"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.flask_server.public_ip]
}
output "public_ip" {
  value = aws_instance.flask_server.public_ip
}
