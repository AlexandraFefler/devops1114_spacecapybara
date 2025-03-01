provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "space_capybara" {
  ami           = "ami-0c02fb55956c7d316" # Amazon Linux 2 AMI
  instance_type = "t2.micro"

  # Associate the existing key pair for SSH access
  key_name = "second-key"

  # Create a security group for SSH and HTTP access
  vpc_security_group_ids = [aws_security_group.space_capybara_sg.id]

  # User data script to install Docker, Docker Compose, and run your app
  user_data = <<-EOF
              #!/bin/bash
              exec > >(tee /var/log/user-data.log | logger -t user-data) 2>&1
              set -x

              yum update -y
              yum install -y docker polkit
              sudo systemctl enable docker
              sudo systemctl start docker
              sudo usermod -aG docker ec2-user


              # Install Docker Compose
              curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
              chmod +x /usr/local/bin/docker-compose
              EOF

  tags = {
    Name = "Space-Capybara-Instance"
  }
}

resource "aws_security_group" "space_capybara_sg" {
  name_prefix = "space-capybara-sg-"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow SSH access from anywhere (limit this for security!)
  }

  ingress {
    from_port   = 5002
    to_port     = 5002
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow HTTP access to the app
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
