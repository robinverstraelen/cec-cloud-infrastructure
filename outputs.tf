locals {
  credentials = { for k, v in local.vms : k => {
    instance_name        = k
    public_ip            = aws_eip.vm[k].public_ip
    ssh_private_key      = tls_private_key.vm[k].private_key_pem
    aws_iam_user         = aws_iam_user.vm[k].name
    aws_console_password = aws_iam_user_login_profile.vm[k].password
  } }
}

output "lab_vm_access_info" {
  sensitive = true
  value = [
    for k in sort(keys(local.vms)) : local.credentials[k]
    if local.vms[k].class == "student"
  ]
}

output "group_vm_access_info" {
  sensitive = true
  value = [
    for k in sort(keys(local.vms)) : local.credentials[k]
    if local.vms[k].class == "group"
  ]
}
