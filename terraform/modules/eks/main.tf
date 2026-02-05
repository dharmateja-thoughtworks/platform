# modules/eks/main.tf

resource "aws_eks_cluster" "main" {
  name     = "${var.env}-${var.cluster_name}"
  role_arn = aws_iam_role.cluster.arn

  vpc_config {
    # Where AWS places the ENIs (Network Interfaces)
    subnet_ids = var.subnet_ids 

    # 1. Private Access: Enabled
    # Allows nodes (in private subnets) to talk to the API server internally
    endpoint_private_access = true

    # 2. Public Access: Enabled (For You!)
    # Allows you to run 'kubectl' from your laptop.
    # In a real Prod environment, you might set this to false and use a VPN.
    endpoint_public_access  = true
  }

  # Ensure IAM Role permissions are created before and deleted after EKS Cluster handling.
  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy
  ]

  tags = {
    Name = "${var.env}-${var.cluster_name}"
  }
}

# modules/eks/main.tf (continued)

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.env}-node-group"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.subnet_ids # Private Subnets

  # The "Muscle" - Instance Sizing
  instance_types = ["t3.medium"] 

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  # Ensure the IAM Role permissions are ready before creating nodes
  depends_on = [
    aws_iam_role_policy_attachment.node_worker,
    aws_iam_role_policy_attachment.node_cni,
    aws_iam_role_policy_attachment.node_registry,
  ]

  tags = {
    Name = "${var.env}-eks-node"
    role = "system"
  }
}