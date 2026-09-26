data "aws_partition" "current" {}


data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    sid     = "AllowEC2AssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}


resource "aws_iam_role" "instance" {
  name               = "${var.name_prefix}-instance-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-instance-role"
  })
}


resource "aws_iam_role_policy_attachment" "instance" {
  role       = aws_iam_role.instance.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


resource "aws_iam_instance_profile" "instance" {
  name = "${var.name_prefix}-instance-profile"
  role = aws_iam_role.instance.name

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-instance-profile"
  })
}