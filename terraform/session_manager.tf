data "aws_caller_identity" "current" {}

resource "aws_kms_key" "session_manager" {
  description         = "Session Manager Key"
  enable_key_rotation = true

  policy = <<POLICY
{
  "Version" : "2012-10-17",
  "Id" : "key-default-1",
  "Statement" : [ {
    "Sid" : "Enable IAM User Permissions",
    "Effect" : "Allow",
    "Principal" : {
      "AWS" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
    },
    "Action" : "kms:*",
    "Resource" : "*"
  },
  {
    "Effect": "Allow",
    "Principal": { "Service": "logs.${var.region}.amazonaws.com" },
    "Action": [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ],
    "Resource": "*"
  }]
}
POLICY
}

resource "aws_cloudwatch_log_group" "session_manager" {
  name       = "/session-manager/"
  kms_key_id = "${aws_kms_key.session_manager.arn}"
}

resource "aws_iam_role_policy" "session_manager" {
  name        = "SessionManager"
  role        = "${aws_iam_role.session_manager.id}"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ssmmessages:CreateControlChannel",
        "ssmmessages:CreateDataChannel",
        "ssmmessages:OpenControlChannel",
        "ssmmessages:OpenDataChannel",
        "ssm:UpdateInstanceInformation"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": "kms:GenerateDataKey",
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt"
      ],
      "Resource": "${aws_kms_key.session_manager.arn}"
    }
  ]
}
POLICY
}

resource "aws_iam_role" "session_manager" {
  name = "SessionManager"
  assume_role_policy = <<POLICY
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
POLICY
}

resource "aws_iam_instance_profile" "session_manager" {
  name = "SessionManager"
  role = "${aws_iam_role.session_manager.name}"
}

resource "aws_ssm_document" "session_manager_settings" {
  name            = "SSM-SessionManagerRunShell"
  document_type   = "Session"
  document_format = "JSON"

  content = <<DOC
{
  "schemaVersion": "1.0",
  "description": "AWS Systems Manager Session Manager settings",
  "sessionType": "Standard_Stream",
  "inputs": {
    "cloudWatchLogGroupName": "${aws_cloudwatch_log_group.session_manager.name}",
    "cloudWatchEncryptionEnabled": true,
    "kmsKeyId": "${aws_kms_key.session_manager.arn}"
  }
}
DOC
}
