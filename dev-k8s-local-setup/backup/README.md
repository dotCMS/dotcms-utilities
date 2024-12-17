# Backup and Restore 

## Overview

This script automates the **backup**, **restore**, and **cleanup** of persistent volumes in a dotCMS Kubernetes cluster. It interacts with Helm charts and Kubernetes resources to ensure smooth backup and restore processes, including scaling down services to ensure data consistency.

---

## Features

- **Backup**: Creates a `.tar.gz` archive of persistent data.
- **Restore**: Restores data from a backup archive.
- **Cleanup**: Removes Helm releases for backup and restore Jobs.
- **Service Management**: Automatically scales down and up `dotcms`, `db`, and `opensearch` services during restore operations.

---

## Prerequisites

Before using the script, ensure the following tools are installed:

1. **kubectl**: For interacting with the Kubernetes cluster.
2. **helm**: To manage Helm charts.
3. A **Kubernetes cluster** running dotCMS services.
4. A valid **Helm chart** for backup and restore operations.

---

## Usage

```bash
./backup_restore.sh <operation> <hostpath> <filename> [namespace]
```

## Parameters

| **Parameter** | **Required** | **Description**                                                       |
|---------------|--------------|-----------------------------------------------------------------------|
| `<operation>` | Yes          | Operation to perform: `backup`, `restore`, or `cleanup`.             |
| `<hostpath>`  | Yes (backup/restore) | Path to the host directory for backup or restore files.            |
| `<filename>`  | Yes (backup/restore) | Name of the backup file to create (backup) or restore from (restore). |
| `[namespace]` | No           | Kubernetes namespace where dotCMS is deployed (default: `dotcms-dev`).|

## Operations

### Backup

Performs a backup of dotCMS persistent data into a .tar.gz file.

Example Command:

```bash
./backup_restore.sh backup /tmp/backup backup-latest.tar.gz
```

Steps:

1. Creates a Helm release dotcms-backup.
2. Backs up persistent data to the specified hostpath.
3. The resulting backup file is named as specified (e.g., backup-latest.tar.gz).

### Restore

Restores data from a specified backup file.

Example Command:

```bash
./backup_restore.sh restore /tmp/backup backup-latest.tar.gz
```

Steps:

1. Validates that the backup file exists.
2. Scales down dotCMS services (dotcms, db, and opensearch).
3. Waits for a grace period to ensure the services are fully stopped.
4. Creates a Helm release dotcms-restore to restore data.
5. Scales up dotCMS services in the correct order:
    - db
    - opensearch
    - dotcms


### Cleanup

Removes Helm releases related to the backup and restore operations.

Example Command:

```bash
./backup_restore.sh cleanup
```

Steps:

1. Uninstalls the dotcms-backup Helm release.
2. Uninstalls the dotcms-restore Helm release.

## Example Use Cases

1. Run a Backup

```bash
./backup_restore.sh backup /tmp/backup backup-20231216.tar.gz
```

2. Restore Data

```bash
./backup_restore.sh restore /tmp/backup backup-20231216.tar.gz
```
3. Cleanup Helm Releases

```bash
./backup_restore.sh cleanup
```


## Error handling

| **Error**                                 | **Cause**                                  | **Solution**                                      |
|-------------------------------------------|-------------------------------------------|--------------------------------------------------|
| `kubectl is not installed.`               | `kubectl` command is not found.            | Install `kubectl` and add it to the system PATH. |
| `helm is not installed.`                  | `helm` command is not found.               | Install `helm` and add it to the system PATH.    |
| `Backup file not found.`                  | Specified file does not exist in hostPath. | Verify the file path and name.                  |
| `Kubernetes cluster is not running.`      | No active Kubernetes cluster detected.     | Start the cluster and verify with `kubectl`.    |
| `Invalid operation '<operation>'`         | Incorrect operation specified.             | Use `backup`, `restore`, or `cleanup`.          |


## Notes

- Ensure the `hostpath` provided exists in the `Docker Desktop` shared directories (for local clusters).
- Backup and restore operations require Helm charts for backup and restore.
- During the restore process:
    - dotCMS services are scaled down to prevent data inconsistencies.
    - Services are restarted in the correct order to ensure dependency resolution.