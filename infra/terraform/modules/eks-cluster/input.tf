variable "map_roles" {
  description = "Additional IAM roles to add to the aws-auth configmap."
  type        = list(map(string))

  default = [
    {
      role_arn = "arn:aws:iam::006393696278:group/DigitalRigAlphaAdmins"
      username = "admins"
      group    = "system:masters"
    },
  ]
}

variable "map_users" {
  description = "Additional IAM users to add to the aws-auth configmap."
  type        = list(map(string))

  default = [
    {
      user_arn = "arn:aws:iam::006393696278:user/damian_baar"
      username = "damian.baar"
      group    = "system:masters"
    },
  ]
}
