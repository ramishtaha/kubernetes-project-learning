# 🔄 Project 15: Disaster Recovery and Backup

**Difficulty**: 🟡 Intermediate  
**Time Estimate**: 3-4 hours  
**Prerequisites**: Projects 01-14 completed, backup/restore concepts  

## 📋 Overview

Implement comprehensive disaster recovery and backup strategies for your Kubernetes cluster! This project demonstrates how to use Velero for cluster backups, configure automated backup workflows, and implement cross-region disaster recovery procedures for business continuity.

## 🎯 Learning Objectives

By the end of this project, you will:
- Implement backup strategies for Kubernetes clusters
- Set up disaster recovery procedures and workflows
- Configure automated backup and restore using Velero
- Implement cross-region backup strategies
- Learn business continuity planning for Kubernetes
- Understand backup testing and validation procedures
- Learn data protection and compliance requirements

## Architecture Overview
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Production    │───▶│     Velero      │───▶│   Backup        │
│    Cluster      │    │   (Backup)      │    │   Storage       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Application   │    │   Scheduled     │    │      DR         │
│     Data        │    │   Backups       │    │    Cluster      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Implementation Steps

### Step 1: Install Velero
```bash
# Install Velero CLI
curl -fsSL -o velero-v1.12.0-linux-amd64.tar.gz https://github.com/vmware-tanzu/velero/releases/download/v1.12.0/velero-v1.12.0-linux-amd64.tar.gz
tar -xzf velero-v1.12.0-linux-amd64.tar.gz
sudo mv velero-v1.12.0-linux-amd64/velero /usr/local/bin/

# Install Velero server
velero install --provider aws --plugins velero/velero-plugin-for-aws:v1.8.0 --bucket velero-backups --secret-file ./credentials --backup-location-config region=us-west-2
```

### Step 2: Configure Backup Storage
```bash
kubectl apply -f storage/
```

### Step 3: Set up Backup Schedules
```bash
kubectl apply -f backups/
```

### Step 4: Test Disaster Recovery
```bash
./scripts/disaster-recovery-test.sh
```

## Files Structure
```
10-disaster-recovery/
├── README.md
├── storage/
│   ├── backup-storage-location.yaml
│   ├── volume-snapshot-location.yaml
│   └── storage-class.yaml
├── backups/
│   ├── daily-backup.yaml
│   ├── weekly-backup.yaml
│   └── app-specific-backup.yaml
├── restore/
│   ├── full-cluster-restore.yaml
│   ├── namespace-restore.yaml
│   └── selective-restore.yaml
├── manifests/
│   ├── sample-stateful-app.yaml
│   └── test-application.yaml
└── scripts/
    ├── setup-velero.sh
    ├── backup-validation.sh
    ├── disaster-recovery-test.sh
    └── restore-procedures.sh
```

## Key Concepts

### Backup Types
- **Full Cluster Backup**: Complete cluster state
- **Namespace Backup**: Specific namespace resources
- **Application Backup**: Application-specific resources and data
- **Volume Snapshots**: Persistent volume data

### Recovery Strategies
- **Point-in-Time Recovery**: Restore to specific timestamp
- **Cross-Cluster Recovery**: Restore to different cluster
- **Selective Recovery**: Restore specific resources
- **Progressive Recovery**: Staged recovery approach

### Backup Storage
- **Object Storage**: S3, GCS, Azure Blob
- **Cross-Region Replication**: Geographic redundancy
- **Encryption**: At-rest and in-transit encryption
- **Retention Policies**: Automated cleanup

## Experiments to Try

### 1. Schedule Regular Backups
```bash
# Create daily backup schedule
velero schedule create daily-backup --schedule="0 2 * * *" --ttl 720h0m0s

# Create weekly full backup
velero schedule create weekly-backup --schedule="0 1 * * 0" --ttl 2160h0m0s --include-namespaces "*"
```

### 2. Test Application Recovery
```bash
# Delete application
kubectl delete namespace test-app

# Restore from backup
velero restore create restore-test-app --from-backup daily-backup-20231215120000
```

### 3. Cross-Cluster Restore
```bash
# Backup from source cluster
velero backup create migration-backup --include-namespaces production

# Restore to target cluster
velero restore create migration-restore --from-backup migration-backup
```

### 4. Volume Snapshot Testing
```bash
# Create volume snapshot
velero backup create volume-backup --include-resources persistentvolumeclaims,persistentvolumes

# Verify snapshot creation
kubectl get volumesnapshot
```

## Troubleshooting

### Common Issues

1. **Backup failures**
   ```bash
   # Check backup status
   velero backup describe backup-name --details
   
   # Check logs
   velero backup logs backup-name
   ```

2. **Storage connectivity issues**
   ```bash
   # Verify storage location
   velero backup-location get
   
   # Test storage access
   kubectl logs -n velero deployment/velero
   ```

3. **Restore failures**
   ```bash
   # Check restore status
   velero restore describe restore-name --details
   
   # Check resource conflicts
   kubectl get events --sort-by='.lastTimestamp'
   ```

### Performance Optimization
```bash
# Optimize backup performance
velero backup create fast-backup --snapshot-volumes=false --default-volumes-to-restic=false

# Parallel processing
velero install --uploader-type=restic --default-repo-maintain-frequency=72h
```

## Disaster Recovery Procedures

### 1. Complete Cluster Loss
```bash
# Step 1: Create new cluster
kind create cluster --name dr-cluster

# Step 2: Install Velero on new cluster
velero install --provider aws --plugins velero/velero-plugin-for-aws:v1.8.0 --bucket velero-backups --secret-file ./credentials --backup-location-config region=us-west-2

# Step 3: Restore from latest backup
velero restore create full-restore --from-backup $(velero backup get --output json | jq -r '.items | sort_by(.metadata.creationTimestamp) | last | .metadata.name')
```

### 2. Namespace Recovery
```bash
# Restore specific namespace
velero restore create namespace-restore --from-backup latest-backup --include-namespaces production

# Verify restoration
kubectl get all -n production
```

### 3. Selective Resource Recovery
```bash
# Restore specific resources
velero restore create selective-restore --from-backup latest-backup --include-resources deployments,services --namespace-mappings production:production-recovered
```

## Business Continuity Planning

### 1. RTO/RPO Objectives
- **Recovery Time Objective (RTO)**: Maximum acceptable downtime
- **Recovery Point Objective (RPO)**: Maximum acceptable data loss
- **Backup Frequency**: Based on RPO requirements
- **Testing Schedule**: Regular DR testing

### 2. Multi-Region Strategy
```yaml
# Cross-region backup storage
apiVersion: velero.io/v1
kind: BackupStorageLocation
metadata:
  name: secondary-region
  namespace: velero
spec:
  provider: aws
  objectStorage:
    bucket: velero-backups-secondary
    prefix: dr-backups
  config:
    region: us-east-1
```

### 3. Automation and Monitoring
```yaml
# Backup monitoring
apiVersion: v1
kind: ConfigMap
metadata:
  name: backup-monitoring
data:
  monitor.sh: |
    #!/bin/bash
    FAILED_BACKUPS=$(velero backup get --output json | jq -r '.items[] | select(.status.phase == "Failed") | .metadata.name')
    if [ ! -z "$FAILED_BACKUPS" ]; then
      echo "Failed backups detected: $FAILED_BACKUPS"
      # Send alert
    fi
```

## Advanced Features

### 1. Application-Consistent Backups
```yaml
# Pre and post backup hooks
apiVersion: v1
kind: Pod
metadata:
  name: database-pod
  annotations:
    pre.hook.backup.velero.io/command: '["/sbin/fsfreeze", "--freeze", "/var/lib/mysql"]'
    post.hook.backup.velero.io/command: '["/sbin/fsfreeze", "--unfreeze", "/var/lib/mysql"]'
```

### 2. Backup Validation
```bash
# Automated backup validation
velero backup create validation-backup --include-namespaces test-app
velero restore create validation-restore --from-backup validation-backup --namespace-mappings test-app:test-app-validation
```

### 3. Cost Optimization
```yaml
# Backup retention and lifecycle
apiVersion: velero.io/v1
kind: Schedule
metadata:
  name: cost-optimized-backup
spec:
  schedule: "0 2 * * *"
  template:
    ttl: 168h0m0s  # 7 days
    includedNamespaces:
    - production
    storageLocation: standard-tier
```

## Compliance and Auditing

### 1. Backup Auditing
```bash
# Generate backup reports
velero backup get --output=custom-columns=NAME:.metadata.name,STATUS:.status.phase,CREATED:.metadata.creationTimestamp

# Compliance reporting
kubectl get events --field-selector involvedObject.kind=Backup --sort-by='.lastTimestamp'
```

### 2. Data Encryption
```yaml
# Encrypted backup storage
apiVersion: velero.io/v1
kind: BackupStorageLocation
metadata:
  name: encrypted-storage
spec:
  provider: aws
  objectStorage:
    bucket: encrypted-velero-backups
  config:
    kmsKeyId: arn:aws:kms:us-west-2:123456789012:key/12345678-1234-1234-1234-123456789012
```

## Next Steps
- Implement chaos engineering for DR testing
- Set up automated failover procedures
- Integrate with CI/CD for backup validation
- Advanced monitoring and alerting

## Cleanup
```bash
# Remove backups
velero backup delete --all

# Uninstall Velero
kubectl delete namespace velero

# Clean up storage
aws s3 rm s3://velero-backups --recursive
```

## Additional Resources
- [Velero Documentation](https://velero.io/docs/)
- [Kubernetes Backup Best Practices](https://kubernetes.io/docs/concepts/cluster-administration/backup/)
- [Disaster Recovery Planning](https://cloud.google.com/architecture/disaster-recovery-planning-guide)
- [AWS EKS Backup Strategies](https://docs.aws.amazon.com/eks/latest/userguide/backup-restore.html)
