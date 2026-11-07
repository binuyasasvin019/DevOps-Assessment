
#!/usr/bin/env bash
set -Eeuo pipefail

# Problem 2 - Ubuntu 24.04 EC2 Bootstrap

# Log failures and clean up temporary files
INSTALL_DIR=""
INSTALL_SCRIPT=""

cleanup() {
    rc=$?

    if [[ -n "$INSTALL_DIR" ]]; then
        rm -rf "$INSTALL_DIR"
    fi

    if [[ -n "$INSTALL_SCRIPT" ]]; then
        rm -f "$INSTALL_SCRIPT"
    fi

    unset DD_API_KEY

    if (( rc != 0 )); then
        echo "BOOTSTRAP_FAILED exit_code=$rc" >&2
    fi
}

trap cleanup EXIT

echo "BOOTSTRAP_STARTED"

# Require root privileges
if [[ "$EUID" -ne 0 ]]; then
    echo "ERROR: Run this script as root."
    exit 1
fi

# Configure non-interactive package installation
export DEBIAN_FRONTEND=noninteractive

# Configuration
SSM_PARAMETER_NAME="${SSM_PARAMETER_NAME:-/petdesk/datadog/api-key}"
AWS_REGION="${AWS_REGION:-ap-southeast-2}"
DD_SITE="${DD_SITE:-datadoghq.com}"
DD_ENV="${DD_ENV:-prod}"

echo "Starting EC2 bootstrap..."
echo "AWS Region: $AWS_REGION"


# Step 1: Install Java if missing


if command -v java >/dev/null 2>&1; then
    echo "Java is already installed."
    java -version
else
    echo "Java not found. Installing OpenJDK 25 LTS..."

    apt-get update
    apt-get install -y --no-install-recommends \
        openjdk-25-jdk-headless

    echo "Java installation completed."
    java -version
fi

echo "Java bootstrap step completed."


# Step 2: Configure unattended security updates


echo "Configuring unattended security updates..."

apt-get update

apt-get install -y --no-install-recommends \
    unattended-upgrades

cat > /etc/apt/apt.conf.d/20auto-upgrades <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
EOF

systemctl enable --now \
    apt-daily.timer \
    apt-daily-upgrade.timer

echo "Unattended security updates configured."


# Step 3: Install AWS CLI v2 if missing


echo "Checking AWS CLI..."

apt-get install -y --no-install-recommends \
    curl ca-certificates python3 unzip

if ! command -v aws >/dev/null 2>&1; then

    echo "AWS CLI not found. Installing AWS CLI v2..."

    INSTALL_DIR="$(mktemp -d)"

    ARCH="$(uname -m)"

    case "$ARCH" in
        x86_64)
            AWS_CLI_ARCH="x86_64"
            ;;
        aarch64)
            AWS_CLI_ARCH="aarch64"
            ;;
        *)
            echo "ERROR: Unsupported architecture: $ARCH"
            exit 1
            ;;
    esac

    curl -fsSL \
        "https://awscli.amazonaws.com/awscli-exe-linux-${AWS_CLI_ARCH}.zip" \
        -o "$INSTALL_DIR/awscliv2.zip"

    unzip -q \
        "$INSTALL_DIR/awscliv2.zip" \
        -d "$INSTALL_DIR"

    "$INSTALL_DIR/aws/install"

    echo "AWS CLI installation completed."
else
    echo "AWS CLI is already installed."
fi

aws --version

echo "AWS CLI bootstrap step completed."


# Step 4: Retrieve Datadog API key from SSM


echo "Retrieving Datadog API key from SSM..."

# Uses temporary credentials from EC2 IAM instance role.
# No AWS access keys are stored in this script.

DD_API_KEY="$(aws ssm get-parameter \
    --name "$SSM_PARAMETER_NAME" \
    --with-decryption \
    --query 'Parameter.Value' \
    --output text \
    --region "$AWS_REGION")"

if [[ -z "$DD_API_KEY" || "$DD_API_KEY" == "None" ]]; then
    echo "ERROR: Unable to retrieve Datadog API key."
    exit 1
fi

echo "Datadog API key retrieved successfully."


# Step 5: Install Datadog Agent 7


echo "Configuring Datadog Agent..."

if ! dpkg-query -W -f='${Status}' datadog-agent \
    2>/dev/null | grep -q "install ok installed"; then

    echo "Installing Datadog Agent 7..."

    INSTALL_SCRIPT="$(mktemp)"

    curl -fsSL \
        https://install.datadoghq.com/scripts/install_script_agent7.sh \
        -o "$INSTALL_SCRIPT"

    DD_API_KEY="$DD_API_KEY" \
    DD_SITE="$DD_SITE" \
    bash "$INSTALL_SCRIPT"

    echo "Datadog Agent installation completed."
else
    echo "Datadog Agent already installed. Skipping installation."
fi


# Step 6: Configure Datadog Agent securely


echo "Updating Datadog Agent configuration..."

install -d -m 0755 /etc/datadog-agent

DD_API_KEY="$DD_API_KEY" \
DD_SITE="$DD_SITE" \
DD_ENV="$DD_ENV" \
python3 - <<'PY'
import os
import tempfile
from pathlib import Path

config_path = Path("/etc/datadog-agent/datadog.yaml")

lines = (
    config_path.read_text().splitlines()
    if config_path.exists()
    else []
)

# Remove previously managed top-level settings
managed_keys = {"api_key", "site", "env"}

lines = [
    line for line in lines
    if not any(
        line.startswith(f"{key}:")
        for key in managed_keys
    )
]

lines.extend([
    f"api_key: {os.environ['DD_API_KEY']}",
    f"site: {os.environ['DD_SITE']}",
    f"env: {os.environ['DD_ENV']}",
])

fd, temporary_path = tempfile.mkstemp(
    dir=str(config_path.parent),
    prefix=".datadog-",
)

try:
    import grp

    dd_agent_gid = grp.getgrnam("dd-agent").gr_gid

     os.fchown(fd, 0, dd_agent_gid)
     os.fchmod(fd, 0o640)

    with os.fdopen(fd, "w") as config_file:
        config_file.write("\n".join(lines) + "\n")

    os.replace(temporary_path, config_path)

finally:
    if os.path.exists(temporary_path):
        os.unlink(temporary_path)
PY

# Remove API key from shell variable
unset DD_API_KEY

echo "Datadog configuration updated."


# Step 7: Enable and verify Datadog Agent


echo "Starting Datadog Agent..."

systemctl enable datadog-agent
systemctl restart datadog-agent

if systemctl is-active --quiet datadog-agent; then
    echo "Datadog Agent configured and running successfully."
else
    echo "ERROR: Datadog Agent failed to start."
    exit 1
fi

echo "BOOTSTRAP_SUCCESS"