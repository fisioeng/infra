
variable "access_key" {}
variable "secret_key" {}
variable "proxy_user" {}
variable "proxy_password" {}

provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "us-east-1"
}

resource "aws_security_group" "deployment_rules" {
  name        = "deployment_slot_rules"
  description = "Allow ssh, GoCD and Consul ports"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8153
    to_port     = 8153
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8500
    to_port     = 8500
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "deployment" {
  ami           = "ami-4fffc834"
  instance_type = "t2.micro"
  key_name = "slot01"
  security_groups = ["deployment_slot_rules"]

  provisioner "remote-exec" {
  	connection {
  		type     	= "ssh"
  		user     	= "ec2-user"
  		private_key = "${file("slot01.pem")}"
    }

    inline = [
    	"sudo yum install -y docker",
    	"sudo service docker start",
    	"sudo mkdir -p /deployment/htpasswd",
      "sudo mkdir -p /deployment/godata",
      "sudo mkdir -p /deployment/consul",
      "sudo chown -R 1000.1000 /deployment/godata",
      "sudo chown -R 1000.1000 /deployment/consul",
      "sudo chmod -R 777 /deployment",
      "sudo echo \"${var.proxy_user}:{SHA}\"$(python -c \"import sha; from base64 import b64encode; print b64encode(sha.new('${var.proxy_password}').digest())\") > /deployment/htpasswd/consul"
    ]
  }
}
