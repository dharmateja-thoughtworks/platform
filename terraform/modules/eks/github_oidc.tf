# terraform/modules/eks/github_oidc.tf

# 1. Fetch existing GitHub OIDC Provider (The "Door")
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

# 2. The IAM Role (The "Badge")
resource "aws_iam_role" "github_actions" {
  name = "${var.env}-github-actions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = data.aws_iam_openid_connect_provider.github.arn
        }
        Condition = {
          StringLike = {
            # 🔒 The Critical Lock: Only YOUR repo can assume this role
            "token.actions.githubusercontent.com:sub": "repo:${var.github_repo}:*"
          }
        }
      }
    ]
  })
}

# 3. The Permissions (The "Keys") - Allow describing cluster to get kubeconfig
resource "aws_iam_policy" "github_eks_policy" {
  name        = "${var.env}-github-eks-policy"
  description = "Allow GitHub Actions to talk to EKS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "eks:DescribeCluster"
        ]
        Resource = aws_eks_cluster.main.arn
      }
    ]
  })
}

# 4. Attach Policy to Role
resource "aws_iam_role_policy_attachment" "github_attach" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_eks_policy.arn
}

# 5. Export the Role ARN (We need this for the GitHub Workflow YAML)
output "github_role_arn" {
  value = aws_iam_role.github_actions.arn
}