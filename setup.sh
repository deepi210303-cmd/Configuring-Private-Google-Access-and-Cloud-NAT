#!/bin/bash
# Configuring Private Google Access and Cloud NAT - Lab Automation Script
# Lab: GSP459 (Google Cloud)
# Last Updated: 2025-08-15

# === Variables (Edit as needed) ===
REGION="us-east1"
ZONE="us-east1-d"
VPC="privatenet"
SUBNET="privatenet-us"
SUBNET_RANGE="10.130.0.0/20"
FW="privatenet-allow-ssh"
VM_INTERNAL="vm-internal"
VM_BASTION="vm-bastion"
NAT_ROUTER="nat-router"
NAT_CONFIG="nat-config"
BUCKET="my-bucket-$(date +%s)"

echo "== Step 1: Create VPC and Custom Subnet =="
gcloud compute networks create $VPC --subnet-mode=custom
gcloud compute networks subnets create $SUBNET \
    --network=$VPC \
    --region=$REGION \
    --range=$SUBNET_RANGE

echo "== Step 2: Create Firewall Rule for SSH =="
gcloud compute firewall-rules create $FW \
    --network=$VPC \
    --allow=tcp:22 \
    --source-ranges=0.0.0.0/0

echo "== Step 3: Create Internal VM (No External IP) =="
gcloud compute instances create $VM_INTERNAL \
    --zone=$ZONE \
    --machine-type=e2-medium \
    --subnet=$SUBNET \
    --no-address

echo "== Step 4: Create Bastion Host VM (With External IP) =="
gcloud compute instances create $VM_BASTION \
    --zone=$ZONE \
    --machine-type=e2-micro \
    --subnet=$SUBNET

echo "== Step 5: Create Cloud Storage Bucket =="
gsutil mb -c MULTI_REGIONAL -l $REGION gs://$BUCKET

echo "== Step 6: Copy Image to Your Bucket =="
gsutil cp gs://cloud-training/gcpnet/private/access.png gs://$BUCKET/

echo "== Step 7: Enable Private Google Access on Subnet =="
gcloud compute networks subnets update $SUBNET \
    --region=$REGION \
    --enable-private-ip-google-access

echo "== Step 8: Create Cloud Router and NAT Gateway (with Logging) =="
gcloud compute routers create $NAT_ROUTER \
    --network=$VPC \
    --region=$REGION

gcloud compute routers nats create $NAT_CONFIG \
    --router=$NAT_ROUTER \
    --region=$REGION \
    --auto-allocate-nat-external-ips \
    --nat-all-subnet-ip-ranges \
    --enable-logging

echo "== Setup Complete! =="
echo "Your Cloud Storage bucket is: gs://$BUCKET"
echo "Now, manually SSH to vm-bastion, then to vm-internal for lab verification."
echo "Test gsutil and apt-get as per lab instructions."
echo "Check Cloud NAT logs in Logs Explorer for connection records."
