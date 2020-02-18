# Create the Codebuild IAM resources
resource "aws_iam_role" "iam_role_nexus" {
  name = "nexus"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
     "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
      }
  ]
}
EOF
}

resource "aws_iam_role_policy" "iam_role_policy_nexus" {
  name = "nexus-role-policy"
  role = "${aws_iam_role.iam_role_nexus.name}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Resource": [
        "*"
      ],
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
    },
    {
      "Action": "*",
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

# Create the Codebuild Project
resource "aws_codebuild_project" "cb_prj_nexus" {
  name = "${terraform.workspace}"
  service_role = "${aws_iam_role.iam_role_nexus.arn}" 

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image = "aws/codebuild/standard:3.0"
    type = "LINUX_CONTAINER"

    environment_variable {
      name  = "NEXUS_APP_NAME"
      value = "${terraform.workspace}"
      type  = "PLAINTEXT"
    }
    
    environment_variable {
      name  = "NEXUS_BUCKET"
      value = "${aws_s3_bucket.s3_bucket_app_tfstate.id}"
      type  = "PLAINTEXT"
    }
  }

  source {
    type            = "GITHUB"
    location        = "${var.source_location}"
    git_clone_depth = 1
  }

  source_version = "master"

  logs_config {
    cloudwatch_logs {
      status      = "ENABLED"
      group_name  = "nexus-logs"
      stream_name = "${terraform.workspace}"
    }
  }
}

# Create the webhook that triggers builds
resource "aws_codebuild_webhook" "cb_webhook" {
  project_name = "${aws_codebuild_project.cb_prj_nexus.name}"

  filter_group {
    filter {
      type = "EVENT"
      pattern = "PUSH"
    }
    
    filter {
      type = "HEAD_REF"
      pattern = "master"
    }
  }
}

resource "aws_s3_bucket" "s3_bucket_app_tfstate" {
  bucket ="${terraform.workspace}-tfbackend"
  acl = "private"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "s3_bucket_public_access_block" {
  bucket = "${aws_s3_bucket.s3_bucket_app_tfstate.id}"

  block_public_acls   = true
  block_public_policy = true
}