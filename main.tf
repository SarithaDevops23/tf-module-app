#create policy

resource "aws_iam_policy" "policy" {
  name        = "${var.component}.${var.env}.ssm.pm.policy"
  path        = "/"
  description = "${var.component}.${var.env}.ssm.pm.policy"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "ssm:GetParameterHistory",
                "ssm:GetParametersByPath",
                "ssm:GetParameters",
                "ssm:GetParameter"
            ],
            "Resource": "arn:aws:ssm:us-east-1:532427859183:parameter/roboshop.dev.*"
        }
    ]
})
}


#IAM role

resource "aws_iam_role" "role" {
  name = "${var.component}.${var.env}.role"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
}

#attaching policy to role

resource "aws_iam_policy_attachment" "policy-attach" {
  name       = "policy-attachment"
  roles      = [aws_iam_role.role.name]
  policy_arn = aws_iam_policy.policy.arn
}

#iam instance profile
resource "aws_iam_instance_profile" "iam_instance_profile" {
  name =  "${var.component}.${var.env}.instanceprofile"
  role = aws_iam_role.role.name
}

#security group

resource "aws_security_group" "sg" {
  name        = "${var.component}.${var.env}.sg"
  description = "Allow TLS inbound traffic"
  

  ingress {
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
    Name = "${var.component}.${var.env}.sg"
  }

  }

#ec2
resource "aws_instance" "instance" {
  ami           = data.aws_ami.ami.id
  instance_type = "t3.small"
  vpc_security_group_ids = [aws_security_group.sg.id]
  iam_instance_profile = aws_iam_instance_profile.iam_instance_profile.name

  tags = {
    Name = "${var.component}-${var.env}"
  }

  
 }

#route53

 resource "aws_route53_record" "dns" {
  zone_id = "Z10122602VAB0LEU37V8Y"
  name    = "${var.component}-${var.env}"
  type    = "A"
  ttl     = 30
  records = [aws_instance.instance.private_ip]
}

#remote exec

 resource "null_resource" "ansible"{
  depends_on = [aws_instance.instance,aws_route53_record.dns]
 

  provisioner "remote-exec" {
    connection {
    type     = "ssh"
    user     = "centos"
    password = "DevOps321"
    host     = aws_instance.instance.public_ip
   }
    inline = [
      "sudo labauto ansible",
      "ansible-pull -i localhost, -U  https://github.com/SarithaDevops23/roboshop-ansible  roboshop.yml -e env=${var.env} -e role_name=${var.component}"
    ]
  }
 }
