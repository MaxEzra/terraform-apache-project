#!/usr/bin/env bash
set -euxo pipefail

# ------- Variables populated by Terraform templatefile() -------
REPO_URL="${repo_url}"
APP_DIR="/opt/myapp"
# ---------------------------------------------------------------

export DEBIAN_FRONTEND=noninteractive

# Update base system and install prerequisites
apt-get update -y
apt-get install -y apache2 libapache2-mod-wsgi-py3 python3-venv git rsync

# Create app directory & Python virtual environment
mkdir -p "${APP_DIR}"
python3 -m venv "${APP_DIR}/venv"

# Clone or update repository
if [ ! -d "${APP_DIR}/repo/.git" ]; then
  git clone "${REPO_URL}" "${APP_DIR}/repo"
else
  cd "${APP_DIR}/repo"
  git pull --ff-only
fi

# Install Python dependencies into venv
source "${APP_DIR}/venv/bin/activate"
pip install --upgrade pip
if [ -f "${APP_DIR}/repo/src/app/requirements.txt" ]; then
  pip install -r "${APP_DIR}/repo/src/app/requirements.txt"
fi

# Sync source to a stable runtime path
mkdir -p "${APP_DIR}/src"
rsync -a --delete "${APP_DIR}/repo/src/" "${APP_DIR}/src/"

# Install Apache site config from the repo
cp "${APP_DIR}/repo/deploy/apache/myapp.conf" /etc/apache2/sites-available/myapp.conf

# Enable site & modules, disable default
a2dissite 000-default || true
a2ensite myapp
a2enmod wsgi

# Start/enable Apache
systemctl enable apache2
systemctl restart apache2
