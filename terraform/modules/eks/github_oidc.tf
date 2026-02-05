# terraform/modules/eks/github_oidc.tf

# 1. The OIDC Provider (The "Door")
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  # GitHub's thumbprint (Publicly available, unlikely to change soon)
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1", "1c58a3a8518e8759bf075b76b750d4f2df264fcd"]
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
          Federated = aws_iam_openid_connect_provider.github.arn
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