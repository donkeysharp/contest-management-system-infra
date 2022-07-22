data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "default" {
  name        = var.image_builder_name
  path        = "/"
  description = "Policy used by Image builder to store logs"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject"
      ],
      "Resource": "arn:aws:s3:::${aws_s3_bucket.builder_data.id}/*"
    }
  ]
}
  EOF
}

resource "aws_iam_role" "builder" {
  name               = var.image_builder_role_name
  assume_role_policy = data.aws_iam_policy_document.assume.json
  tags               = var.tags
}

resource "aws_iam_instance_profile" "builder" {
  name = var.image_builder_role_name
  role = aws_iam_role.builder.name
}

resource "aws_iam_role_policy_attachment" "bucket_access" {
  role       = aws_iam_role.builder.name
  policy_arn = aws_iam_policy.default.arn
}

resource "aws_iam_role_policy_attachment" "builder_access" {
  role       = aws_iam_role.builder.name
  policy_arn = "arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilder"
}

resource "aws_iam_role_policy_attachment" "ssm_access" {
  role       = aws_iam_role.builder.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
