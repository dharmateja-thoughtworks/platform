variable "env" {
  description = "The environment name (e.g., dev, prod)"
  type        = string
}

variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
  default = "my-eks-cluster"
}

variable "vpc_id" {
  description = "VPC ID where the cluster will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the EKS cluster (usually private)"
  type        = list(string)
}

variable "github_repo" {
  description = "The GitHub repository in 'owner/repo' format (e.g., 'yourname/my-eks-project')"
  type        = string
  default = "dharmateja-thoughtworks/platform"
}