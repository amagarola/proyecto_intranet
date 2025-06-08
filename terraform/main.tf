module "k3s_cluster" {
  source               = "./modules/k3s-cluster"
  security_group_id    = aws_security_group.k3s_sg.id
  iam_instance_profile = aws_iam_instance_profile.ec2_ssm_profile.name
  subnet_ids           = ["subnet-04a08c25e59902a54"]
}

module "proxy" {
  source = "./modules/proxy"
  # depends_on           = [module.helm_releases.argocd] # Comentado o eliminado
  ami_id               = "ami-0e449927258d45bc4"
  instance_type        = var.instance_type
  subnet_id            = var.subnet_id
  vpc_id               = var.vpc_id
  domains              = var.domains
  name                 = "ec2-proxy"
  target_ip            = module.k3s_cluster.master_private_ip
  k3s_private_key_pem  = module.k3s_cluster.private_key_pem
  iam_instance_profile = aws_iam_instance_profile.ec2_ssm_profile.name
}

resource "aws_iam_role" "ec2_ssm_role" {
  name = "ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_core_attach" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_policy" "cluster_autoscaler" {
  name        = "cluster-autoscaler-policy"
  description = "Policy for Kubernetes Cluster Autoscaler to manage ASG nodes"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeTags",
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
          "ec2:DescribeLaunchTemplateVersions"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cluster_autoscaler_attach" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = aws_iam_policy.cluster_autoscaler.arn
}

resource "aws_iam_instance_profile" "ec2_ssm_profile" {
  name = "ec2-ssm-profile"
  role = aws_iam_role.ec2_ssm_role.name
}

resource "aws_s3_bucket" "tfstate" {
  bucket        = "proyecto-intranet-tfstate"
  force_destroy = true
  acl           = "private"

  versioning {
    enabled = true
  }

  tags = {
    Name        = "Terraform State Bucket"
    Environment = "dev"
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
