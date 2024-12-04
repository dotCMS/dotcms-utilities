# DotCMS Local Development Setup using Kubernetes

## Overview
This script automates the setup of a local development environment for DotCMS using Kubernetes. It ensures that all necessary tools and configurations are in place, making it easy for developers to focus on their work instead of worrying about infrastructure setup.

---

## Features
1. **Tool Installation**:
   - Automatically checks for required tools: `kubectl`, `helm`, `mkcert`, and `jq`.
   - Installs missing tools using Homebrew.

2. **Kubernetes Configuration**:
   - Ensures Kubernetes is running on Docker Desktop.
   - Installs the NGINX Ingress Controller to manage external access to services.

3. **TLS Certificate Management**:
   - Generates a secure TLS certificate using `mkcert`.
   - Stores certificates in a hidden folder in the user's home directory (`~/.dotcms/certificates`).
   - Creates or updates a Kubernetes secret for the certificate.

4. **Namespace and Secret Setup**:
   - Creates the necessary Kubernetes namespace if it doesn’t exist.
   - Checks if the TLS secret exists, updates it if expired, or creates a new one.

5. **Local Host Configuration**:
   - Adds `dotcms.local` to the system’s `hosts` file for local access.

---

## How to Use
1. **Pre-requisites**:
   - Ensure you have Docker Desktop installed and Kubernetes enabled.

2. **Run the Script**:
   - Make the script executable:
     ```bash
     chmod +x setup_dev.sh
     ```
   - Execute the script:
     ```bash
     ./setup_dev.sh
     ```

3. **Follow the Logs**:
   - The script provides real-time feedback with checkmarks (✅) for successful steps and warnings (❌) for missing configurations.

4. **Access DotCMS**:
   - After completing the setup, you will be able to install DotCMS using the Helm Chart.

---

## Troubleshooting
- **Kubernetes Not Found**: Ensure Docker Desktop is running and Kubernetes is enabled.
- **Certificate Issues**: Delete the `~/.dotcms/certificates` folder and rerun the script to regenerate certificates.
- **Hosts File Permissions**: Run the script with `sudo` if it cannot update the `/etc/hosts` file.

---

## Notes
- This script is designed for macOS users.
- It prepares the environment for deploying DotCMS using a Helm Chart.
- Future iterations may include support for other operating systems.

---

## Contribution
Feel free to contribute to this script by submitting issues or pull requests to the repository.

---
