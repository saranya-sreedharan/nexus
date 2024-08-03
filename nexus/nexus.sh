#!/bin/bash

# Color codes for formatting output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Function to display error message and exit
display_error() {
    echo -e "${RED}Error: $1${NC}" >&2
    exit 1
}

# Function to display success message
display_success() {
    echo -e "${GREEN}$1${NC}"
}

# Update package lists
sudo apt update || display_error "Failed to update package lists"

# Add OpenJDK repository
echo | sudo add-apt-repository ppa:openjdk-r/ppa || display_error "Failed to add OpenJDK repository"
sudo apt-get update || display_error "Failed to update package lists after adding repository"

# Install OpenJDK 8
sudo apt-get install openjdk-8-jdk openjdk-8-jre -y || display_error "Failed to install OpenJDK 8"

# Verify Java installation
java -version || display_error "Java installation failed"

# Set JAVA_HOME environment variable
export JAVA_HOME=$(readlink -f $(which java) | sed "s:bin/java::")

# Create Nexus directories
mkdir app || display_error "Failed to create 'app' directory"
cd app || display_error "Failed to change directory to 'app'"

# Download Nexus tarball
wget https://download.sonatype.com/nexus/3/nexus-3.66.0-02-unix.tar.gz || display_error "Failed to download Nexus tarball"
tar -xvf nexus-3.66.0-02-unix.tar.gz || display_error "Failed to extract Nexus tarball"
rm nexus-3.66.0-02-unix.tar.gz || display_error "Failed to remove Nexus tarball"

# Create Nexus user
sudo adduser --system --no-create-home --group nexus || display_error "Failed to create Nexus user"

# Set ownership of Nexus directories
sudo chown -R nexus:nexus /home/ubuntu/app/nexus || display_error "Failed to set ownership of Nexus directory"
sudo chown -R nexus:nexus /home/ubuntu/app/sonatype-work

# Modify Nexus configuration
sudo sed -i 's/#run_as_user=""/run_as_user="nexus"/' ~/app/nexus/bin/nexus.rc || display_error "Failed to modify Nexus configuration"

# Create systemd service unit file for Nexus
sudo tee /etc/systemd/system/nexus.service > /dev/null <<EOF
[Unit]
Description=Nexus Repository Manager

[Service]
Type=forking
ExecStart=/home/ubuntu/app/nexus/bin/nexus start
ExecStop=/home/ubuntu/app/nexus/bin/nexus stop
User=nexus
Restart=on-abort

[Install]
WantedBy=multi-user.target
EOF

# Set permissions for Nexus service unit file
sudo chmod 644 /etc/systemd/system/nexus.service || display_error "Failed to set permissions for Nexus service unit file"

# Reload systemd daemon
sudo systemctl daemon-reload || display_error "Failed to reload systemd daemon"

# Start Nexus service
~/app/nexus/bin/nexus start || display_error "Failed to start Nexus service"

# Display success message
display_success "Nexus repository setup completed successfully"
