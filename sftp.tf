resource "aws_eip" "elastic_ip" {
}


resource "aws_transfer_server" "sftp" {
  identity_provider_type = "SERVICE_MANAGED"
  logging_role = aws_iam_role.sftp-logging.arn
  endpoint_type = "VPC"

  endpoint_details {
    vpc_id = module.vpc.vpc_id
    subnet_ids = [module.vpc.private_subnets[0]]
    address_allocation_ids = ["aws_eip.elastic_ip.allocation_id"]
  }


}

resource "aws_iam_role" "sftp-logging" {
  name = "sftp-logging-role"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
        "Effect": "Allow",
        "Principal": {
            "Service": "transfer.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
        }
    ]
}
EOF

  tags = {
    Name       = "sftp-transfer-logging-role"
    Terraform  = "true"
  }
}

resource "aws_iam_role_policy" "sftp-logging" {
  name = "sftp-logging-policy"
  role = aws_iam_role.sftp-logging.id

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:DescribeLogStreams",
                "logs:CreateLogGroup",
                "logs:PutLogEvents"
            ],
            "Resource": "*"
        }
    ]
}
POLICY

}

resource "aws_s3_bucket" "sftp" {
  bucket = "sftp-example"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = {
    Name       = "sftp-example"
  }
}

# resource "aws_route53_record" "sftpserver" {
#
#   zone_id = var.aws_route53_id
#   name    = "sftp.domain.com"
#   type    = "CNAME"
#   ttl     = "300"
#
#   records = [aws_transfer_server.sftp.endpoint]
# }

resource "aws_iam_role" "sftp" {
  name = "sftp-${var.username}-user-role"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
        "Effect": "Allow",
        "Principal": {
            "Service": "transfer.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
        }
    ]
}
EOF

  tags = {
    Name       = "sftp-${var.username}-user-role"
    Terraform  = "true"
  }
}

resource "aws_iam_role_policy" "sftp" {
  name = "sftp-${var.username}-user-policy"
  role = aws_iam_role.sftp.id

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowListingFolder",
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket",
                "s3:GetBucketLocation"
            ],
            "Resource": "${local.s3_bucket_arn}",
            "Condition": {
                "StringLike": {
                    "s3:prefix": [
                        "${var.username}/*",
                        "${var.username}"
                    ]
                }
            }
        },
        {
            "Sid": "AllowReadWriteToObject",
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:DeleteObjectVersion",
                "s3:DeleteObject",
                "s3:GetObjectVersion"
            ],
            "Resource": "${local.s3_bucket_arn}/${var.username}*"
        }
    ]
}
POLICY
}

resource "aws_transfer_user" "user" {
  server_id      = aws_transfer_server.sftp.id
  user_name      = var.username
  role           = aws_iam_role.sftp.arn
  home_directory = "/${local.s3_bucket_name}/${var.username}"
}

resource "aws_transfer_ssh_key" "user" {
  server_id = aws_transfer_server.sftp.id
  user_name = aws_transfer_user.user.user_name
  body      = var.sshkey

}

locals {
  s3_bucket_arn  = aws_s3_bucket.sftp.arn
  s3_bucket_name = aws_s3_bucket.sftp.id
}
