 #!/bin/bash
sudo yum update -y && sudo yum update -y docker
sudo systemctl start docker
# add ec2-user to docker group
sudo usermod -aG docker ec2-user
docker run -p 8080:80 nginx