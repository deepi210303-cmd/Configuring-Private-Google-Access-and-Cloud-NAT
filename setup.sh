#!/bin/bash
# Configuring Private Google Access and Cloud NAT - Lab Automation

REGION=us-central1
ZONE=us-central1-a
VPC=privatenet
SUBNET=privatenet-us
SUBNET_RANGE=10.130.0.0/20
FW=privatenet-allow-ssh
VM_INTERNAL=vm-internal
VM_BASTION=vm-bastion
NAT_ROUTER=nat-router
NAT_CONFIG=nat-config
BUCKET=my-bucket-$(date +%s)

echo "=== Creating VPC and Subnet ==="
gcloud compute networks create $VPC --subnet-mode=custom
gcloud compute networks subnets create $SUBNET \
    --network=$VPC \
    --region=$REGION \
    --range=$SUBNET_RANGE

echo "=== Creating Firewall Rule for SSH ==="
gcloud compute firewall-rules create $FW \
    --network=$VPC \
    --allow=tcp:22 \
    --source-ranges=0.0.0.0/0

echo "=== Creating Internal VM (No external IP) ==="
gcloud compute instances create $VM_INTERNAL \
    --zone=$ZONE \
    --machine-type=e2-medium \
    --subnet=$SUBNET \
    --no-address

echo "=== Creating Bastion Host (with external IP) ==="
gcloud compute instances create $VM_BASTION \
    --zone=$ZONE \
    --machine-type=e2-micro \
    --subnet=$SUBNET

echo "=== Creating Cloud Storage Bucket ==="
gsutil mb -l $REGION gs://$BUCKET

echo "=== Copying image to your bucket ==="
gsutil cp gs://cloud-training/gcpnet/private/access.png gs://$BUCKET/

echo "=== Enabling Private Google Access on Subnet ==="
gcloud compute networks subnets update $SUBNET \
    --region=$REGION \
    --enable-private-ip-google-access

echo "=== Creating Cloud Router and NAT Gateway ==="
gcloud compute routers create $NAT_ROUTER \
    --network=$VPC \
    --region=$REGION

gcloud compute routers nats create $NAT_CONFIG \
    --router=$NAT_ROUTER \
    --region=$REGION \
    --auto-allocate-nat-external-ips \
    --nat-all-subnet-ip-ranges \
    --enable-logging

echo "=== Setup Complete! ==="
echo "Your bucket name is: $BUCKET"
echo "Now test SSH, gsutil, apt-get update, and NAT logging as per lab instructions."
