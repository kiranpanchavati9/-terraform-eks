resource "aws_eks_cluster" "main" {
  name     = "dev"
  role_arn = aws_iam_role.cluster.arn
  version  = "1.35"

  access_config {
    authentication_mode = "API"
  }

  vpc_config {
    subnet_ids = [
      "subnet-0e9272cbed90dc89c",
      "subnet-05ff6038d2dcf648e",
    ]
  }
}

resource "aws_eks_node_group" "main" {
  cluster_name  = aws_eks_cluster.main.name
  node_role_arn = aws_iam_role.node.arn
  subnet_ids = [
    "subnet-0e9272cbed90dc89c",
    "subnet-05ff6038d2dcf648e",
  ]
  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 10
  }

  update_config {
    max_unavailable = 1
  }
}
