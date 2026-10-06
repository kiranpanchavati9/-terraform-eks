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
    max_size     = 10
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }
}

resource "aws_eks_access_entry" "workstation" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = "arn:aws:iam::798701233543:role/workstation-role"
  type = "STANDARD"
}

resource "aws_eks_access_policy_association" "workstation" {
  cluster_name  = aws_eks_cluster.main.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = "arn:aws:iam::798701233543:role/workstation-role"
  access_scope {
    type       = "cluster"
  }
}

resource "null_resource" "kubeconfig" {
    triggers = {
        cluster_name = timestamp()
    }
    provisioner "local-exec" {
        command = "rm -rf ~/.kube/config && aws eks update-kubeconfig --name dev"
    }
}


