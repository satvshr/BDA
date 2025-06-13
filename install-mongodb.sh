#!/bin/bash

# MongoDB Installation Script for Ubuntu/Debian
# This script will install and configure MongoDB Community Edition

set -e  # Exit on any error

echo "🍃 MongoDB Installation Script"
echo "=============================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root. Please run as a regular user with sudo privileges."
   exit 1
fi

# Check if sudo is available
if ! command_exists sudo; then
    print_error "sudo is required but not installed. Please install sudo first."
    exit 1
fi

print_status "Starting MongoDB installation..."

# Get Ubuntu codename
UBUNTU_CODENAME=$(lsb_release -cs)
print_status "Detected Ubuntu codename: $UBUNTU_CODENAME"

# Step 1: Update package index
print_status "Updating package index..."
sudo apt update

# Step 2: Install required packages
print_status "Installing required packages..."
sudo apt install -y wget curl gnupg2 software-properties-common apt-transport-https ca-certificates lsb-release

# Try MongoDB official repository first, with fallback to Ubuntu repository
if [[ "$UBUNTU_CODENAME" == "noble" ]]; then
    print_warning "Ubuntu 24.04 (Noble) detected. Using compatible repository..."
    REPO_CODENAME="jammy"  # Use jammy (22.04) repo for noble (24.04)
else
    REPO_CODENAME="$UBUNTU_CODENAME"
fi

print_status "Attempting to install MongoDB from official repository..."

# Step 3: Import MongoDB public GPG key
print_status "Adding MongoDB GPG key..."
if curl -fsSL https://pgp.mongodb.com/server-7.0.asc | sudo gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor; then
    print_success "MongoDB GPG key added successfully"
else
    print_warning "Failed to add MongoDB GPG key, will try alternative installation method"
fi

# Step 4: Add MongoDB repository
print_status "Adding MongoDB repository..."
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu $REPO_CODENAME/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list

# Step 5: Update package index and try to install from official repo
print_status "Updating package index with MongoDB repository..."
if sudo apt update 2>/dev/null; then
    print_status "Installing MongoDB Community Edition from official repository..."
    if sudo apt install -y mongodb-org 2>/dev/null; then
        print_success "MongoDB installed from official repository"
        MONGODB_INSTALLED=true
    else
        print_warning "Failed to install from official repository, trying alternative..."
        MONGODB_INSTALLED=false
    fi
else
    print_warning "Official MongoDB repository not accessible, trying alternative..."
    MONGODB_INSTALLED=false
fi

# Fallback: Install from Ubuntu's default repositories
if [ "$MONGODB_INSTALLED" != "true" ]; then
    print_status "Installing MongoDB from Ubuntu default repositories..."
    
    # Remove the problematic MongoDB repository
    sudo rm -f /etc/apt/sources.list.d/mongodb-org-7.0.list
    sudo apt update
    
    # Install MongoDB from Ubuntu repos
    if sudo apt install -y mongodb; then
        print_success "MongoDB installed from Ubuntu repositories"
        MONGODB_SERVICE="mongodb"
        MONGODB_CONFIG="/etc/mongodb.conf"
        MONGODB_DATA_DIR="/var/lib/mongodb"
        MONGODB_LOG_DIR="/var/log/mongodb"
    else
        print_error "Failed to install MongoDB from any source"
        exit 1
    fi
else
    MONGODB_SERVICE="mongod"
    MONGODB_CONFIG="/etc/mongod.conf"
    MONGODB_DATA_DIR="/var/lib/mongodb"
    MONGODB_LOG_DIR="/var/log/mongodb"
fi

# Step 6: Start and enable MongoDB service
print_status "Starting MongoDB service..."
sudo systemctl start $MONGODB_SERVICE

print_status "Enabling MongoDB to start on boot..."
sudo systemctl enable $MONGODB_SERVICE

# Step 7: Create MongoDB data directory with proper permissions
print_status "Setting up MongoDB data directory..."
sudo mkdir -p $MONGODB_DATA_DIR
sudo mkdir -p $MONGODB_LOG_DIR
if id "mongodb" &>/dev/null; then
    sudo chown -R mongodb:mongodb $MONGODB_DATA_DIR
    sudo chown -R mongodb:mongodb $MONGODB_LOG_DIR
else
    print_warning "mongodb user not found, using current user permissions"
    sudo chown -R $USER:$USER $MONGODB_DATA_DIR
    sudo chown -R $USER:$USER $MONGODB_LOG_DIR
fi
sudo chmod 755 $MONGODB_DATA_DIR

# Step 8: Configure MongoDB for development
if [ "$MONGODB_SERVICE" = "mongod" ]; then
    print_status "Configuring MongoDB for development..."
    sudo cp $MONGODB_CONFIG $MONGODB_CONFIG.backup

    # Create a temporary config file
    cat > /tmp/mongod_config << 'EOF'
# mongod.conf

# for documentation of all options, see:
#   http://docs.mongodb.org/manual/reference/configuration-options/

# Where to store the data.
storage:
  dbPath: /var/lib/mongodb
  journal:
    enabled: true

# where to write logging data.
systemLog:
  destination: file
  logAppend: true
  path: /var/log/mongodb/mongod.log

# network interfaces
net:
  port: 27017
  bindIp: 127.0.0.1

# how the process runs
processManagement:
  timeZoneInfo: /usr/share/zoneinfo

#security:

#operationProfiling:

#replication:

#sharding:

## Enterprise-Only Options:

#auditLog:

#snmp:
EOF

    sudo mv /tmp/mongod_config $MONGODB_CONFIG
    sudo chown root:root $MONGODB_CONFIG
    sudo chmod 644 $MONGODB_CONFIG
else
    # For mongodb (not mongod), configuration is simpler
    print_status "Configuring MongoDB from Ubuntu repositories..."
    sudo tee $MONGODB_CONFIG > /dev/null << 'EOF'
# mongodb.conf

# Where to store the data
dbpath=/var/lib/mongodb

# Where to log
logpath=/var/log/mongodb/mongodb.log
logappend=true

# Port
port = 27017

# Listen to all interfaces
bind_ip = 127.0.0.1

# Enable journaling
journal=true
EOF
fi

# Step 9: Restart MongoDB to apply new configuration
print_status "Restarting MongoDB with new configuration..."
sudo systemctl restart $MONGODB_SERVICE

# Step 10: Wait a moment for MongoDB to start
sleep 5

# Step 11: Verify installation
print_status "Verifying MongoDB installation..."

# Check if MongoDB service is running
if sudo systemctl is-active --quiet $MONGODB_SERVICE; then
    print_success "MongoDB service is running!"
else
    print_error "MongoDB service is not running. Checking status..."
    sudo systemctl status $MONGODB_SERVICE
    print_status "Trying to start MongoDB again..."
    sudo systemctl start $MONGODB_SERVICE
    sleep 3
    if sudo systemctl is-active --quiet $MONGODB_SERVICE; then
        print_success "MongoDB service is now running!"
    else
        print_error "Failed to start MongoDB service"
        exit 1
    fi
fi

# Check for MongoDB shell
if command_exists mongosh; then
    MONGO_CMD="mongosh"
elif command_exists mongo; then
    MONGO_CMD="mongo"
else
    print_warning "MongoDB shell not found. Installing mongosh..."
    # Try to install mongosh
    if wget -qO - https://pgp.mongodb.com/server-7.0.asc | sudo apt-key add - 2>/dev/null; then
        echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu $REPO_CODENAME/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list
        sudo apt update 2>/dev/null && sudo apt install -y mongodb-mongosh 2>/dev/null
    fi
    
    if command_exists mongosh; then
        MONGO_CMD="mongosh"
    elif command_exists mongo; then
        MONGO_CMD="mongo"
    else
        print_warning "MongoDB shell not available, but MongoDB server should be running"
        MONGO_CMD=""
    fi
fi

# Test MongoDB connection
if [ -n "$MONGO_CMD" ]; then
    print_status "Testing MongoDB connection..."
    if timeout 10 $MONGO_CMD --eval "db.adminCommand('ping')" --quiet > /dev/null 2>&1; then
        print_success "MongoDB is responding to connections!"
    else
        print_warning "MongoDB connection test failed, but service is running"
    fi
else
    print_warning "Skipping connection test - MongoDB shell not available"
fi

# Step 12: Show MongoDB status
print_status "MongoDB installation summary:"
echo "================================"
if [ -n "$MONGO_CMD" ]; then
    $MONGO_CMD --eval "db.version()" --quiet 2>/dev/null || echo "MongoDB Community Edition"
else
    echo "MongoDB Community Edition"
fi
echo "Service: $MONGODB_SERVICE"
echo "Service Status: $(sudo systemctl is-active $MONGODB_SERVICE)"
echo "Port: 27017"
echo "Data Directory: $MONGODB_DATA_DIR"
echo "Log Directory: $MONGODB_LOG_DIR"
echo "Config File: $MONGODB_CONFIG"

# Step 13: Create initial database and test user (for development)
if [ -n "$MONGO_CMD" ]; then
    print_status "Setting up initial database for Library Management System..."
    $MONGO_CMD --eval "
    use library_db;
    db.test.insertOne({message: 'MongoDB is working!', timestamp: new Date()});
    print('✓ Database library_db created');
    print('✓ Test document inserted');
    " --quiet 2>/dev/null || print_warning "Could not create test database, but MongoDB is running"
else
    print_status "MongoDB is running. You can connect manually once a MongoDB shell is available."
fi

print_success "🎉 MongoDB installation completed successfully!"
echo ""
echo "🔧 Useful MongoDB commands:"
echo "  Start MongoDB:    sudo systemctl start $MONGODB_SERVICE"
echo "  Stop MongoDB:     sudo systemctl stop $MONGODB_SERVICE"
echo "  Restart MongoDB:  sudo systemctl restart $MONGODB_SERVICE"
echo "  Check Status:     sudo systemctl status $MONGODB_SERVICE"
echo "  View Logs:        sudo journalctl -u $MONGODB_SERVICE -f"
if [ -n "$MONGO_CMD" ]; then
    echo "  Connect to Shell: $MONGO_CMD"
fi
echo ""
echo "📊 MongoDB is now ready for your Library Management System!"
echo "   Database: library_db"
echo "   Connection: mongodb://localhost:27017"
echo ""
echo "🚀 You can now run your backend with:"
echo "   cd BDA/backend && sbt run" 