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
      "subnet-05ff6038d2dcf648e"
    ]
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy
  ]
}

resource "aws_eks_node_group" "main" {
  cluster_name  = aws_eks_cluster.main.name
  node_role_arn = aws_iam_role.node.arn

  subnet_ids = [
    "subnet-0e9272cbed90dc89c",
    "subnet-05ff6038d2dcf648e"
  ]

  scaling_config {
    desired_size = 1
    max_size     = 10
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_worker_policy,
    aws_iam_role_policy_attachment.node_cni_policy,
    aws_iam_role_policy_attachment.node_ecr_policy
  ]
}

resource "aws_eks_access_entry" "workstation" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = "arn:aws:iam::798701233543:role/workstation-role"
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "workstation" {
  cluster_name  = aws_eks_access_entry.workstation.cluster_name
  principal_arn = aws_eks_access_entry.workstation.principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}

resource "null_resource" "kubeconfig" {
  depends_on = [
    aws_eks_access_policy_association.workstation
  ]

  triggers = {
    cluster_name     = aws_eks_cluster.main.name
    cluster_endpoint = aws_eks_cluster.main.endpoint
  }

  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --name ${aws_eks_cluster.main.name} --region us-east-1"
  }
}