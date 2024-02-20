# Gym Data Tracker Flask App Deployment Guide

This guide covers the deployment steps for the Gym Data Tracker.
Gym Data tracker is a CRUD app for entering and displaying workout data for my gym sessions.

## Prerequisites
- AWS CLI configured with access rights
- Docker installed and configured
- `kubectl` and `eksctl` installed
- Helm installed
- Access to an AWS ECR repository

## Installation Steps

### Running the Script
- Make the script executable: `chmod +x install.sh`
- Run the script: `./install.sh`
- This will install the cluster, the app and its database as well as prometheus/grafana and monitoring dashboards for it
