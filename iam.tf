resource "aws_iam_user" "vm" {
  for_each = local.vms
  name     = each.key
}

resource "aws_iam_user_login_profile" "vm" {
  for_each                = local.vms
  user                    = aws_iam_user.vm[each.key].name
  password_reset_required = false
}

resource "aws_iam_policy" "vm_control" {
  for_each = local.vms
  name     = "${each.key}-ec2-control"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ec2:StartInstances",
          "ec2:StopInstances",
          "ec2:RebootInstances",
        ],
        Resource = [aws_instance.vm[each.key].arn]
      },
      {
        Effect   = "Allow",
        Action   = "ec2:DescribeInstances",
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_policy" "allow_change_password" {
  name = "AllowChangeOwnPassword"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "iam:ChangePassword"
        ],
        Resource = "arn:aws:iam::*:user/$${aws:username}"
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "vm_control" {
  for_each   = local.vms
  user       = aws_iam_user.vm[each.key].name
  policy_arn = aws_iam_policy.vm_control[each.key].arn
}

resource "aws_iam_user_policy_attachment" "change_password" {
  for_each   = local.vms
  user       = aws_iam_user.vm[each.key].name
  policy_arn = aws_iam_policy.allow_change_password.arn
}
