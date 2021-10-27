provider aws{
    region= "ap-south-1"
    profile= "default"
}

resource "aws_vpc" "lwterra" {
  
  cidr_block       = "10.0.0.0/16"

  tags = {
    Name = "web_vpc"
  }
}

resource "aws_subnet" "subnet1" {
  depends_on= [aws_vpc.lwterra]
  vpc_id     = aws_vpc.lwterra.id
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = true
  cidr_block = "10.0.1.0/24"
  tags = {
    Name = "web_subnet1"
  }
}


resource "aws_internet_gateway" "igw" {
  depends_on= [aws_vpc.lwterra]
  vpc_id = aws_vpc.lwterra.id

  tags = {
    Name = "web_igw"
  }
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.lwterra.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "web_route_table"
  }
}

resource "aws_route_table_association" "rt_subnet_asso" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_security_group" "web_sg" {
  name        = "web_allow_all"
  description = "Allow all traffic"
  vpc_id      = aws_vpc.lwterra.id

  ingress {
    description      = "Allow all Port"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web_allow_all"
  }
}


resource "aws_instance" "web" {
    ami= "ami-010aff33ed5991201" 
    availability_zone = "ap-south-1a"
    instance_type= "t2.micro"
    key_name= "keypair1"
    vpc_security_group_ids= ["${aws_security_group.web_sg.id}"] 
    subnet_id= aws_subnet.subnet1.id 
    tags={
        Name= "webos"
    }
}

resource "aws_ebs_volume" "ebs1"{
    availability_zone= aws_instance.web.availability_zone
    size= 1
    tags={
        Name= "web_hd"
    }
}

resource "aws_volume_attachment" "ebs_attach"{
    device_name= "/dev/xvdc"
    volume_id= aws_ebs_volume.ebs1.id
    instance_id= aws_instance.web.id 
}

resource "null_resource" "webapp" {
           
    connection{
        type= "ssh"
        user= "ec2-user"
        private_key= file("C:/Users/Admin/Documents/terraformtraining/task5/keypair1.pem")
        host= aws_instance.web.public_ip
    }

    provisioner "remote-exec" {
        inline= [
            "sudo yum install httpd -y",
            "sudo systemctl start httpd",
            "sudo yum install git -y",
            "sudo git clone https://github.com/Tanmay4443/terraform-task-5.git",
            "sudo mkfs.ext4  /dev/xvdc",
            "sudo mount /dev/xvdc /var/www/html",
            "sudo cp /home/ec2-user/terraform_task_5/index.html  /var/www/html"
        ]
    }
}

resource "null_resource" "chrome"  {


	provisioner "local-exec" {
	    command = "chrome  http://${aws_instance.web.public_ip}"
  	}
}