# Add beside main.tf and iam.tf in your existing EKS Terraform repository.
# Uses the existing AWS provider and aws_eks_cluster.main resource.
# Requires a recent AWS provider supporting optional OIDC thumbprints.

locals {
  eks_oidc_issuer = aws_eks_cluster.main.identity[0].oidc[0].issuer
  eks_oidc_host   = replace(local.eks_oidc_issuer, "https://", "")
}

resource "aws_iam_openid_connect_provider" "eks" {
  url            = local.eks_oidc_issuer
  client_id_list = ["sts.amazonaws.com"]
}

resource "aws_iam_role" "ebs_csi" {
  name_prefix = "dev-ebs-csi-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.eks.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.eks_oidc_host}:aud" = "sts.amazonaws.com"
          "${local.eks_oidc_host}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ebs_csi" {
  role       = aws_iam_role.ebs_csi.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEBSCSIDriverPolicyV2"
}

# Resolves a compatible version; pin addon_version after the first successful
# deployment to keep future plans from automatically selecting newer releases.
data "aws_eks_addon_version" "ebs_csi" {
  addon_name         = "aws-ebs-csi-driver"
  kubernetes_version = aws_eks_cluster.main.version
  most_recent        = true
}

resource "aws_eks_addon" "ebs_csi" {
  cluster_name             = aws_eks_cluster.main.name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = data.aws_eks_addon_version.ebs_csi.version
  service_account_role_arn = aws_iam_role.ebs_csi.arn

  depends_on = [
    aws_iam_role_policy_attachment.ebs_csi,
    aws_eks_node_group.main
  ]
}

output "ebs_csi_addon_version" {
  description = "Installed EBS CSI add-on version."
  value       = aws_eks_addon.ebs_csi.addon_version
}
