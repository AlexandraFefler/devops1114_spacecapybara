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

              # Create app directory
              mkdir /space_capybara
              cd /space_capybara

              # Create init.sql
              cat <<EOD > init.sql
              -- Create the database if it doesn't already exist
              CREATE DATABASE IF NOT EXISTS mydatabase;

              -- Use the database
              USE mydatabase;

              CREATE TABLE IF NOT EXISTS visitor_counter (
                  id INT PRIMARY KEY AUTO_INCREMENT,
                  count INT DEFAULT 0
              );

              INSERT INTO visitor_counter (count) VALUES (0) ON DUPLICATE KEY UPDATE count = count;

              -- Create the table if it doesn't already exist
              CREATE TABLE IF NOT EXISTS images (
                idimages INT NOT NULL AUTO_INCREMENT,
                imagescol VARCHAR(300) NULL,
                PRIMARY KEY (idimages)
              );

              -- Insert data only if it doesn't already exist
              INSERT INTO images (idimages, imagescol)
              SELECT 1, 'https://api.capy.lol/v1/capybara'
              WHERE NOT EXISTS (SELECT 1 FROM images WHERE idimages = 1);

              INSERT INTO images (idimages, imagescol)
              SELECT 2, 'https://media.tenor.com/inZYR5pCZP8AAAAM/capybara-cat.gif'
              WHERE NOT EXISTS (SELECT 1 FROM images WHERE idimages = 2);

              INSERT INTO images (idimages, imagescol)
              SELECT 3, 'https://media0.giphy.com/media/bnl7xKaEXMLhI475je/200w.gif?cid=6c09b952idcgtsfmgcpfuq9d4cmh9lwin5815h5g632ti0d4&ep=v1_gifs_search&rid=200w.gif&ct=g'
              WHERE NOT EXISTS (SELECT 1 FROM images WHERE idimages = 3);

              INSERT INTO images (idimages, imagescol)
              SELECT 4, 'https://i.dailymail.co.uk/i/pix/2017/07/04/10/4203D62400000578-0-image-a-48_1499161248603.jpg'
              WHERE NOT EXISTS (SELECT 1 FROM images WHERE idimages = 4);
              EOD

              # Create docker-compose.yml
              cat <<EOD > docker-compose.yml
              version: '3.8'

              services:
                web:
                  image: sashafefler/spacecapybara:v5
                  ports:
                    - "5002:5002"
                  environment:
                    - FLASK_ENV=development
                    - MYSQL_HOST=db
                    - MYSQL_USER=user
                    - MYSQL_PASSWORD=password
                    - MYSQL_DATABASE=mydatabase
                    - WEB_PORT=5002
                  depends_on:
                    - db

                db:
                  image: mysql:8.0
                  container_name: mysql_container
                  restart: always
                  environment:
                    MYSQL_ROOT_PASSWORD: admin
                    MYSQL_DATABASE: mydatabase
                    MYSQL_USER: user
                    MYSQL_PASSWORD: password
                  ports:
                    - "3307:3306"
                  volumes:
                    - db_data:/var/lib/mysql
                    - ./init.sql:/docker-entrypoint-initdb.d/init.sql:ro

              volumes:
                db_data:
              EOD

              # Start Docker Compose
              docker-compose up -d
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
