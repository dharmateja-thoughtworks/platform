# terraform/modules/eks/auth.tf
# Configure EKS cluster access for IAM roles

data "aws_eks_cluster_auth" "main" {
  name = aws_eks_cluster.main.name
}

provider "kubernetes" {
  host                   = aws_eks_cluster.main.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.main.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.main.token
}

# Update existing aws-auth ConfigMap to allow GitHub Actions role access
resource "kubernetes_config_map_v1_data" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = yamlencode(concat(
      # Node Group Role (default)
      [
        {
          rolearn  = aws_iam_role.node.arn
          username = "system:node:{{EC2PrivateDNSName}}"
          groups   = ["system:bootstrappers", "system:nodes"]
        }
      ],
      # GitHub Actions Role
      aws_iam_role.github_actions.arn != "" ? [
        {
          rolearn  = aws_iam_role.github_actions.arn
          username = "github-actions"
          groups   = ["system:masters"]  # Full cluster admin access for GitHub Actions
        }
      ] : [],

      # GitLab CI Role
      aws_iam_role.gitlab_ci.arn != "" ? [
        {
          rolearn  = aws_iam_role.gitlab_ci.arn
          username = "gitlab-ci"
          groups   = ["system:masters"]  # Full cluster admin access for GitLab CI
        }
      ] : []
    ))
  }

  force = true
  depends_on = [aws_eks_cluster.main, aws_iam_role.github_actions]
}
