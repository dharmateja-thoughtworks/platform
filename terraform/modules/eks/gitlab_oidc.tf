# 1. Get GitLab's Certificate dynamically (The Senior Way)
data "tls_certificate" "gitlab" {
  url = "https://gitlab.com"
}

# 2. Create the OIDC Provider
resource "aws_iam_openid_connect_provider" "gitlab" {
  url             = "https://gitlab.com"
  client_id_list  = ["https://gitlab.com"]
  thumbprint_list = [data.tls_certificate.gitlab.certificates[0].sha1_fingerprint]
}

# 3. Create the IAM Role for GitLab CI
resource "aws_iam_role" "gitlab_ci" {
  name = "${var.env}-gitlab-ci-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.gitlab.arn
        }
        Condition = {
          StringLike = {
            # 🔒 LOCK DOWN: Only allow THIS specific GitLab repo
            # Format: project_path:{group}/{project}:*
            "gitlab.com:sub": "project_path:dharmateja-thoughtworks/k8s-platform-repo:*" 
          }
        }
      }
    ]
  })
}

# 4. Attach Permissions (Administrator for now, scoping down later)
resource "aws_iam_role_policy_attachment" "gitlab_admin" {
  role       = aws_iam_role.gitlab_ci.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# 5. Output the ARN (So you can use it in GitLab CI variables)
output "gitlab_role_arn" {
  value = aws_iam_role.gitlab_ci.arn
}