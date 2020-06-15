provider "aws" {
	region  = "ap-south-1"
	profile = "Akshay"
}

resource "aws_key_pair" "my_key" {
  	key_name   = "newkwy11"
  	public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD3F6tyPEFEzV0LX3X8BsXdMsQz1x2cEikKDEY0aIj41qgxMCP/iteneqXSIFZBp5vizPvaoIR3Um9xK7PGoW8giupGn+EPuxIA4cDM4vzOqOkiMPhz5XK0whEjkVzTo4+S0puvDZuwIsdiW9mxhJc7tgBNL0cYlWSYVkz4G/fslNfRPW5mYAM49f4fhtxPb5ok4Q2Lg9dPKVHO/Bgeu5woMc7RY0p1ej6D4CKFE6lymSDJpW0YHX/wqE9+cfEauh7xZcG0q9t2ta6F6fmX0agvpFyZo8aFbXeUBr7osSCJNgvavWbM/06niWrOvYX2xwWdhXmXSrbX8ZbabVohBK41 "
}
resource "aws_security_group" "srule" {
	
	name = "allow_httpd"

	ingress {

		from_port  = 80
		to_port    = 80
		protocol   = "tcp"
		cidr_blocks = ["0.0.0.0/0"]

		
	}
	
	ingress {
		
		from_port  = 22
		to_port    = 22
		protocol   = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}
	
	egress {
		from_port  = 0
		to_port    = 0
		protocol   = "-1"
		cidr_blocks = ["0.0.0.0/0"]
	}
	
	tags = {
	Name = "allow_httpd"
	}
}


resource "aws_instance"  "web" {

	depends_on = [
		aws_security_group.srule,
	]

	ami             = "ami-0447a12f28fddb066"
	instance_type   = "t2.micro"
	key_name        = "newkey11"
	security_groups = ["allow_httpd"]
	tags = {
		Name = "apos1"
	}
	
	connection {
		type        = "ssh"
		user        = "ec2-user"
		private_key = file("C:/Users/acer/Downloads/newkey11.pem")
		host        = aws_instance.web.public_ip
	}
	
	provisioner "remote-exec" {
		inline = [
			"sudo yum install httpd php git -y",
			"sudo systemctl restart httpd",
			"sudo systemctl enable httpd",
		]
	}	

}

resource "aws_ebs_volume" "esb1" {
	depends_on = [
		aws_instance.web		
	]
	availability_zone = aws_instance.web.availability_zone
	size              = 1
	tags = {
		Name ="lwmyhd"
	}
}

resource "aws_volume_attachment" "ebs_att"{
	depends_on = [
		aws_ebs_volume.esb1		
	]
	device_name  = "/dev/sdh"
	volume_id    = "${aws_ebs_volume.esb1.id}"
	instance_id  = "${aws_instance.web.id}"
	force_detach = true
}

resource "null_resource" "nulllocal2" {
	provisioner "local-exec" {
		command = "echo ${aws_instance.web.public_ip} > publicip.txt"
	}
}

resource "null_resource" "nullremote3" {

	depends_on = [
		aws_volume_attachment.ebs_att,
	]

	connection {
		type = "ssh"
		user = "ec2-user"
		private_key = file("C:/Users/acer/Downloads/newkey11.pem")
		host = aws_instance.web.public_ip
	}
	provisioner "remote-exec" {
		inline = [
			"sudo mkfs.ext4  /dev/xvdh",
			"sudo mount /dev/xvdh  /var/www/html",
			"sudo rm -rf /var/www/html/*",
			"sudo git clone https://github.com/akshaypatidar5/cloudtask1.git  /var/www/html/"
		]
	}
}



resource "aws_s3_bucket" "mybuck" {
	depends_on = [
		null_resource.nullremote3
	]
	bucket = "121ap121"
	acl = "public-read"

}

resource "aws_s3_bucket_object" "obj1" {
	depends_on = [
		aws_s3_bucket.mybuck
	]
	bucket = "121ap121"
	key = "ap.jpg"
	source = "C:/Users/acer/Desktop/simp/ap.jpg"
	acl = "public-read"
	content_type= "image/jpg"
	
}

variable "var1" {
	default = "s3-"
}

locals {
s3_origin_id = "${var.var1}${aws_s3_bucket.mybuck.id}"
}


resource "aws_cloudfront_distribution" "s3_distribution" {
	origin {
	domain_name = "${aws_s3_bucket.mybuck.bucket_regional_domain_name}"
	origin_id   = "${local.s3_origin_id}"
	}

  	enabled             = true
  	is_ipv6_enabled     = true
  	comment             = "Some comment"
  
	default_cache_behavior {
    		allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    		cached_methods   = ["GET", "HEAD"]
    		target_origin_id = "${local.s3_origin_id}"

    		forwarded_values {
      			query_string = false

	      		cookies {
        			forward = "none"
      			}
    		}

    	viewer_protocol_policy = "allow-all"
    
 	}
	
	restrictions {
    		geo_restriction {
      			restriction_type = "none"
    		}
  	}

	viewer_certificate {
    		cloudfront_default_certificate = true
  	}

	depends_on=[
		aws_s3_bucket_object.obj1
	]

	connection {
		type = "ssh"
		user = "ec2-user"
		private_key = file("C:/Users/acer/Downloads/newkey11.pem")
		host = aws_instance.web.public_ip
	}
	provisioner "remote-exec" {
		inline = [
				"sudo su << EOF",
            					"echo \"<center><img src='http://${self.domain_name}/${aws_s3_bucket_object.obj1.key}'></center>\" >> /var/www/html/index.html",
           					"EOF"
			]
	}


}

resource "null_resource" "nulllocal1" {

	depends_on = [
		aws_cloudfront_distribution.s3_distribution
	]

	provisioner "local-exec" {
		command = "start chrome  ${aws_instance.web.public_ip}"
	}
}




