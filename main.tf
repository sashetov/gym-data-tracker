provider "aws" {
  profile = "interview_free_acct"
  region = "us-west-2" # Set your desired AWS region
}
resource "aws_security_group" "flask_security_group" {
  name_prefix = "flask-sg-"
  vpc_id = "vpc-08a427d3952213b57"
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
  subnet_id          = "subnet-00ab85e47e214105f"
  associate_public_ip_address = true
  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum -y install git httpd mod_proxy mod_proxy_http
              systemctl start httpd
              systemctl enable httpd
              echo "<VirtualHost *:80>
                      ServerName localhost
                      ProxyPass / http://127.0.0.1:5000/
                      ProxyPassReverse / http://127.0.0.1:5000/
                  </VirtualHost>" > /etc/httpd/conf.d/reverse-proxy.conf
              systemctl restart httpd
              git clone https://github.com/sashetov/test.git ~/flask-hello-world
              cd ~/flask-hello-world
              python3 -m venv env
              source env/bin/activate
              pip install -r requirements.txt
              flask run
              EOF
}
output "public_ip" {
  value = aws_instance.flask_server.public_ip
}
