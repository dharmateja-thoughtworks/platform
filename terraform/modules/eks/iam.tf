# modules/eks/iam.tf

# ==============================================================================
# 1. Cluster Role (Control Plane)
# ==============================================================================

resource "aws_iam_role" "cluster" {
  name = "${var.env}-${var.cluster_name}-cluster-role"

  # The "Trust Policy": Who can wear this badge? -> EKS Service
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
  })

  tags = {
    Name = "${var.env}-eks-cluster-role"
  }
}

# Attach the necessary AWS Managed Policy
resource "aws_iam_role_policy_attachment" "cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

# ==============================================================================
# 2. Node Group Role (Worker Nodes)
# ==============================================================================

resource "aws_iam_role" "node" {
  name = "${var.env}-${var.cluster_name}-node-role"

  # The "Trust Policy": Who can wear this badge? -> EC2 Service
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = {
    Name = "${var.env}-eks-node-role"
  }
}

# Attach Policy 1: Worker Node Policy (To join the cluster)
resource "aws_iam_role_policy_attachment" "node_worker" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node.name
}

# Attach Policy 2: CNI Policy (To give IPs to Pods) - CRITICAL!
resource "aws_iam_role_policy_attachment" "node_cni" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node.name
}

# Attach Policy 3: Container Registry (To pull images)
resource "aws_iam_role_policy_attachment" "node_registry" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node.name
}