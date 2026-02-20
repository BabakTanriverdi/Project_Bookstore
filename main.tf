# https://registry.terraform.io/providers/hashicorp/aws/latest
# https://registry.terraform.io/providers/integrations/github/latest/docs
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~>6.0"
    }
    github = {
      source = "integrations/github"
      version = "6.11.1"
  }
}
}

provider "aws" {
  # Configuration options
  region = "us-east-1"
}


provider "github" {
  # Configuration options
    token = data.aws_ssm_parameter.token.value
}
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter
data "aws_ssm_parameter" "token" {
  name = "babak-token" # The name of the parameter in AWS Systems Manager Parameter Store
}

variable "keyname" {
    description = "The name of the key pair to use for EC2 instances"
    type        = string
    default     = "mod_1_key" # Replace with your actual key pair name
  
}

variable "gituser" {
    description = "The GitHub username"
    type        = string
    default     = "BabakTanriverdi" # Replace with your actual GitHub username
}

# https://registry.terraform.io/providers/integrations/github/latest/docs#authentication
# https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository
resource "github_repository" "gitrepo" {
  name        = "Project_Bookstore_TF"
  description = "My awesome codebase"
  auto_init     = true
  visibility = "public"
}

variable "files" {
default = ["bookstore-api.py", "requirements.txt", "Dockerfile", "docker-compose.yml"]
}

# https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_file
resource "github_repository_file" "appfiles" {
  repository          = github_repository.gitrepo.name
  branch              = "main"
  for_each            = toset(var.files)
  file                = each.value # The name of the file to create in the repository
  content             = file(each.value)
  commit_message      = "Add app files"
  overwrite_on_create = true
}

# locals {
#   # all files in the "app" directory and its subdirectories 
#   app_files = fileset(path.module, "app/**")
# }

# resource "github_repository_file" "appfiles" {
#   repository          = github_repository.gitrepo.name
#   branch              = github_branch.mybranch.branch
#   for_each            = local.app_files
#   file                = each.value
#   content             = file("${path.module}/${each.value}")
#   commit_message      = "Add app files"
#   overwrite_on_create = true
# }

resource "aws_security_group" "tf-docker-sg" {
    name = "docker-sec-gr-203-CH11tr"
    tags = {
        Name = "project-203-docker"
    }
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_instance" "tf-docker-ec2" {
    ami = "ami-0f3caa1cf4417e51b"   # Amazon Linux 2023 AMI 
    instance_type = "t3.micro"
    key_name = var.keyname
    vpc_security_group_ids = [ aws_security_group.tf-docker-sg.id ]
    tags = {
        Name = "Web Server of Bookstore"
    }

    user_data = templatefile("userdata.sh", {
        git-token = data.aws_ssm_parameter.token.value,
        git-username = var.gituser
        }
    )
    depends_on = [ github_repository.gitrepo, github_repository_file.appfiles ]
}

# data "aws_ami" "amazon_linux_2023" {
#   most_recent = true
#   owners      = ["amazon"]

#   filter {
#     name   = "name"
#     values = ["al2023-ami-*-x86_64"]
#   }

# }

# resource "aws_instance" "tf-docker-ec2" {
#     ami                    = data.aws_ami.amazon_linux_2023.id
#     instance_type          = "t3.micro"
#     key_name               = var.keyname
#     vpc_security_group_ids = [aws_security_group.tf-docker-sg.id]
#     tags = {
#         Name = "Web Server of Bookstore"
#     }

#     user_data = templatefile("userdata.sh", {
#         git-token    = data.aws_ssm_parameter.token.value,
#         git-username = var.gituser
#     })
    
#     depends_on = [github_repository.gitrepo, github_repository_file.appfiles]
# }


output "webserver-url" {
    value = "http://${aws_instance.tf-docker-ec2.public_ip}"
}
