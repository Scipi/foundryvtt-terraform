resource "aws_iam_role_policy" "foundry_s3_access_policy" {
  name   = "${var.name}_foundry_s3_access_policy"
  role   = aws_iam_role.foundry_role.id
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "s3:ListAllMyBuckets",
            "Resource": "*"
        }, 
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:ListBucket",
                "s3:PutObject",
                "s3:PutObjectAcl"
            ],
            "Resource": [
                "arn:aws:s3:::${var.name}-vtt-assets-${var.domain}",
                "arn:aws:s3:::${var.name}-vtt-assets-${var.domain}/*"
            ]
        }
    ]
}
EOF
}
resource "aws_iam_role" "foundry_role" {
  name = "${var.name}_foundry_role"

  assume_role_policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "ec2.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  }
  EOF
}
resource "aws_s3_bucket" "vtt-assets" {
  bucket = "${var.name}-vtt-assets-${replace(var.domain,".","-")}"
  acl    = "public-read"
  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["PUT", "POST", "HEAD"]
    allowed_origins = ["https://${var.domain}"]
    expose_headers  = []
    max_age_seconds = 3000
  }
}