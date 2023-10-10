provider "aws" {
  region = "ap-south-1"
}

resource "aws_security_group" "allow-ssh" {
  name        = "allow-ssh"
  description = "allow ssh to cli users"

 ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags= {
    Name = "allow-ssh"
  }
}

resource "aws_security_group" "egress-all" {
  name        = "egress-all"
  description = "allow all outgoing traffic"

 egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # Indicates all protocols
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags= {
    Name = "egress-all"
  }
}

resource "aws_instance" "Demo" {
  ami           = "ami-08e5424edfe926b43"
  instance_type = "z1d.metal"
  key_name = "eksa-admin"
  security_groups= ["allow-ssh", "egress-all"]
  tags = {
    Name = "eksa_admin"
  }
}

resource "null_resource" "copy_files" {
 triggers = {
  instance_id = aws_instance.Demo.id
 }

  provisioner "local-exec" {
    command = "chmod +x local-exec.sh; ./local-exec.sh ${aws_instance.Demo.public_ip} /var/lib/cloud/instance/boot-finished 600"
  }
 
  provisioner "remote-exec" {
      connection {
      type        = "ssh"
      host        = aws_instance.Demo.public_ip
      user        = "ubuntu"
      private_key = file("~/.aws/key-pairs/eksa-admin.pem")
    }

      inline = [
      "chmod +x /home/ubuntu/vm-scripts/*.sh",
      "mkdir /home/ubuntu/vm-scripts/logs",
      "sudo bash /home/ubuntu/vm-scripts/install-pre-requisites.sh > /home/ubuntu/vm-scripts/logs/install-pre-requisites.log 2>&1",
      "sudo bash /home/ubuntu/vm-scripts/create-network.sh > /home/ubuntu/vm-scripts/logs/create-network.log 2>&1",
      "sudo bash /home/ubuntu/vm-scripts/launch-admin.sh > /home/ubuntu/vm-scripts/logs/launch-admin.log 2>&1",
      "sudo bash /home/ubuntu/vm-scripts/launch-vms.sh > /home/ubuntu/vm-scripts/logs/launch-vms.log 2>&1",
    ]
  }

}
