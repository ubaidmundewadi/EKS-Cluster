#!/bin/bash
## Create EKS cluster

eksctl create cluster \
--name MERN \
--version 1.30 \
--region us-east-1 \
--nodegroup-name mern-linux-nodes \
--nodes 2 \
--nodes-min 1 \
--nodes-max 4 \
--node-type t3.medium \
--node-volume-size 8 \
--ssh-access \
--ssh-public-key vprofile-prod-key \
--managed


## Download and create IAM policy

curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json

aws iam create-policy --policy-name ALBIngressControllerIAMPolicy --policy-document file://iam_policy.json


## Create IAM OIDC provider
eksctl utils associate-iam-oidc-provider --cluster MERN --approve

## Create IAM service account

eksctl create iamserviceaccount \
  --name alb-ingress-controller \
  --namespace kube-system \
  --cluster MERN \
  --attach-policy-arn arn:aws:iam::<account_id>:policy/ALBIngressControllerIAMPolicy \
  --approve

## Install ALB Ingress Controller


helm repo add eks https://aws.github.io/eks-charts
helm repo update

helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=<cluster_name> \
  --set serviceAccount.create=false \
  --set serviceAccount.name=alb-ingress-controller

