# Problem 2 — EC2 Instance Bootstrap

## Overview

This solution provides an idempotent Bash bootstrap script for an Amazon EC2 instance running Ubuntu 24.04 LTS. The script is designed to execute on every boot and reboot, installing required software and configuring automatic security updates and monitoring.

**Files:**
- `bootstrap.sh` — Installs Java, configures unattended upgrades, and installs/configures Datadog Agent 7.
- `ec2-bootstrap.service` — systemd unit that runs the bootstrap script on every startup.
- `ec2-ssm-policy.json` — IAM permissions for retrieving the Datadog API key from AWS Systems Manager Parameter Store.

## 1. Bootstrap Script

The script performs three main operations:

1. **OpenJDK:** Checks whether Java is installed. If absent, installs OpenJDK 21 LTS from Ubuntu repositories. The installed version should be checked against the latest LTS available in the target Ubuntu repositories.
2. **Automatic security updates:** Installs `unattended-upgrades`, enables daily package-list updates and automatic upgrades, and enables the corresponding systemd timers.
3. **Datadog Agent:** Retrieves the API key at runtime from an SSM SecureString parameter, installs Datadog Agent 7 using the official installer if missing, updates its configuration, and verifies that the service is running.

The script uses package installation checks and consistent configuration settings to support repeated execution. It emits `BOOTSTRAP_STARTED`, `BOOTSTRAP_SUCCESS`, and `BOOTSTRAP_FAILED` messages for monitoring.

## 2. Running on Every Startup and Deployment Strategy

**Selected approach: cloud-init for initial provisioning and systemd for repeated execution.**

The bootstrap script is designed to execute on every boot and reboot. I selected a systemd oneshot service because it provides reliable startup execution, service status tracking, and integration with systemd journaling.

For newly provisioned EC2 instances, I would use an EC2 Launch Template with cloud-init user data to install `bootstrap.sh` into `/usr/local/sbin/`, install `ec2-bootstrap.service` into `/etc/systemd/system/`, reload systemd, and enable the service. The service would then execute on every boot and reboot without manual intervention.

For existing EC2 instances, I would use AWS Systems Manager Run Command or State Manager to distribute the files and enable the service across the fleet, avoiding manual SSH access.

### Service installation commands

The following commands would be executed automatically by the provisioning mechanism on the EC2 instance:

```bash
sudo install -m 0750 bootstrap.sh /usr/local/sbin/ec2-bootstrap.sh

sudo install -m 0644 ec2-bootstrap.service \
  /etc/systemd/system/ec2-bootstrap.service

sudo systemctl daemon-reload
sudo systemctl enable ec2-bootstrap.service
sudo systemctl start ec2-bootstrap.service
```

### Verification

```bash
sudo systemctl status ec2-bootstrap.service
sudo journalctl -u ec2-bootstrap.service -b --no-pager
```

For a fleet of 50 instances, execution results would be collected centrally through CloudWatch rather than checked manually on individual servers.

**Deployment assumption:** The provisioning mechanism must make the bootstrap script and service file available locally before executing the installation commands. Existing-instance deployment through Systems Manager additionally requires managed-instance connectivity and permissions.

## 3. IAM Instance Role Permissions and IMDSv2

The EC2 instance requires an IAM role attached through an instance profile. This allows the instance to obtain temporary AWS credentials without storing access keys in the bootstrap script.

The role must trust the EC2 service principal (`ec2.amazonaws.com`).

### Required IAM permissions

- **`ssm:GetParameter`** — Allows the instance to retrieve the Datadog API key from the SSM Parameter Store parameter `/petdesk/datadog/api-key`.
- **`kms:Decrypt` (conditional)** — Required if the SecureString parameter uses a customer-managed KMS key. Access should be restricted to the relevant key and, where appropriate, the SSM encryption context.

The file `ec2-ssm-policy.json` provides the least-privilege SSM permission. Its `ACCOUNT_ID` placeholder must be replaced with the target AWS account ID during deployment.

### IMDSv2

IMDSv2 is enforced using the EC2 metadata option `HttpTokens=required`.

The AWS CLI automatically retrieves temporary credentials from the EC2 instance role using IMDSv2. The bootstrap script does not need to retrieve metadata tokens manually or store permanent AWS credentials.

The instance also requires network access to SSM, Ubuntu package repositories, the Datadog installer, and Datadog intake endpoints.

## 4. Detecting Bootstrap Failures Across 50 EC2 Instances

For a fleet of 50 instances, I would implement centralized monitoring using Amazon CloudWatch rather than manually logging in to each instance.

### Failure detection approach

1. **Local execution status:** The bootstrap script exits with a nonzero status when a command fails. The systemd service records the result.
2. **Structured log messages:** The script emits `BOOTSTRAP_STARTED`, `BOOTSTRAP_SUCCESS`, and `BOOTSTRAP_FAILED` messages.
3. **Centralized logging:** Configure the CloudWatch Agent or another log collector to forward the systemd journal entries for `ec2-bootstrap.service` to CloudWatch Logs.
4. **Failure alerts:** Create CloudWatch Logs metric filters for `BOOTSTRAP_FAILED` and configure CloudWatch alarms to send notifications through Amazon SNS.
5. **Missing execution detection:** Track expected completion signals for each instance after boot. Alert if a running instance fails to report successful completion within a defined time window.
6. **Fleet visibility:** Use CloudWatch dashboards and Systems Manager to identify failed instances and investigate their logs.

### Example

If 49 instances complete bootstrap successfully and one instance fails to retrieve its Datadog API key from SSM, the failing instance would produce a `BOOTSTRAP_FAILED` message and a nonzero systemd service result.

Centralized logging and monitoring would identify the affected instance without requiring manual SSH access.

The monitoring infrastructure is proposed as an architecture design and has not been deployed as part of this assessment.

## 5. Idempotency and Security Considerations

The bootstrap script is designed to support repeated execution on every startup.

- **Java:** Checks whether Java is already available before installing OpenJDK.
- **Unattended upgrades:** Reapplies the same automatic update configuration and ensures the required timers are enabled.
- **Datadog:** Checks whether the Agent package is installed before running the installer.
- **API key:** Retrieves the Datadog API key from SSM Parameter Store at runtime instead of embedding it in the script.
- **Configuration security:** Writes the Datadog configuration using an atomic file replacement and restrictive file permissions.
- **Error handling:** Uses `set -Eeuo pipefail` and an exit trap to report unsuccessful execution.
- **Repeat execution:** The Datadog Agent is currently restarted on every successful bootstrap, even if its configuration has not changed. This could be optimized by restarting only when required.

### Additional security considerations

The SSM parameter should be stored as a SecureString, and access should be restricted to the instance role.

The Datadog installer is downloaded over HTTPS. In a production environment, I would verify or pin the installer and test the installation process before deploying it across the fleet.

The script updates standard top-level YAML settings in `datadog.yaml`. This approach should be tested against the installed Datadog configuration to ensure unrelated settings are preserved.

## 6. Validation and Assumptions

### Completed validation

The Bash script passed local syntax validation:

```bash
bash -n bootstrap.sh
```

The IAM policy was checked for valid JSON syntax:

```bash
python3 -m json.tool ec2-ssm-policy.json
```

The IAM policy was also checked using AWS IAM Access Analyzer before replacing the account ID with a placeholder. Access Analyzer returned no findings.