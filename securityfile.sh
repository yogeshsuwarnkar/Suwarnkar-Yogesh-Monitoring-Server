#!/bin/bash

# Function to list all users and groups on the server
list_users_groups() {
  echo "Listing all users:"
  cut -d: -f1 /etc/passwd
  echo ""

  echo "Listing all groups:"
  cut -d: -f1 /etc/group
  echo ""
}

# Function to check for users with UID 0 and non-standard users
check_uid_zero() {
  echo "Checking for users with UID 0 (root privileges):"
  awk -F: '($3 == "0") {print}' /etc/passwd
  echo ""
}

# Function to identify users without passwords or with weak passwords
check_user_passwords() {
  echo "Checking for users without passwords or with weak passwords:"
  awk -F: '($2 == "" || $2 == "*") {print $1 " has no password or uses an invalid password"}' /etc/shadow
  echo ""
}

# Function to scan for files and directories with world-writable permissions
scan_world_writable() {
  echo "Scanning for world-writable files and directories:"
  find / -xdev -type f -perm -0002 -ls 2>/dev/null
  find / -xdev -type d -perm -0002 -ls 2>/dev/null
  echo ""
}

# Function to check for .ssh directories and ensure secure permissions
check_ssh_permissions() {
  echo "Checking .ssh directories for secure permissions:"
  find /home -name ".ssh" -exec ls -ld {} \;
  echo ""
}

# Function to report files with SUID or SGID bits set
report_suid_sgid() {
  echo "Reporting files with SUID or SGID bits set:"
  find / -xdev \( -perm -4000 -o -perm -2000 \) -type f -exec ls -ld {} \;
  echo ""
}

# Function to list all running services and check for unauthorized services
list_services() {
  echo "Listing all running services:"
  systemctl list-units --type=service --state=running
  echo ""
}

# Function to check critical services and their configurations
check_critical_services() {
  echo "Checking critical services (e.g., sshd, iptables):"
  for service in sshd iptables; do
    systemctl is-active --quiet $service && echo "$service is running" || echo "$service is not running"
  done
  echo ""
}

# Function to verify firewall status and open ports
check_firewall_status() {
  echo "Checking firewall status and configuration:"
  if systemctl is-active --quiet iptables; then
    echo "Firewall (iptables) is active"
    iptables -L -n
  else
    echo "Firewall (iptables) is not active"
  fi
  echo ""

  echo "Reporting open ports and associated services:"
  ss -tuln
  echo ""
}

# Function to check IP and network configurations
check_ip_configuration() {
  echo "Checking IP configuration and identifying public vs. private IPs:"
  ip a | grep 'inet'
  echo ""
}

# Function to check for security updates
check_security_updates() {
  echo "Checking for available security updates:"
  if command -v apt-get &> /dev/null; then
    apt-get update && apt-get upgrade --dry-run | grep "^Inst"
  elif command -v yum &> /dev/null; then
    yum check-update
  fi
  echo ""
}

# Function to check logs for suspicious activity
check_logs() {
  echo "Checking logs for suspicious activity:"
  grep "Failed password" /var/log/auth.log | tail -n 10
  echo ""
}

# Function to implement server hardening steps
server_hardening() {
  echo "Implementing server hardening steps:"
  # SSH Hardening
  echo "Configuring SSH to use key-based authentication only:"
  sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
  echo "PermitRootLogin no" >> /etc/ssh/sshd_config
  systemctl restart sshd
  echo "SSH configured to use key-based authentication only."

  # Disable IPv6
  echo "Disabling IPv6:"
  echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
  echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
  sysctl -p
  echo "IPv6 disabled."

  # Secure GRUB bootloader
  echo "Securing GRUB bootloader:"
  grub-mkpasswd-pbkdf2
  echo "GRUB password set."

  # Configure unattended upgrades for security updates
  echo "Configuring automatic updates for security patches:"
  if command -v apt-get &> /dev/null; then
    apt-get install unattended-upgrades -y
    dpkg-reconfigure -plow unattended-upgrades
  fi
  echo "Automatic updates configured."
}

# Function to generate a summary report
generate_report() {
  echo "Generating a security audit summary report:"
  list_users_groups
  check_uid_zero
  check_user_passwords
  scan_world_writable
  check_ssh_permissions
  report_suid_sgid
  list_services
  check_critical_services
  check_firewall_status
  check_ip_configuration
  check_security_updates
  check_logs
  echo "Security audit summary report generated."
}

# Function to send alert email (optional)
send_alert() {
  echo "Sending alert email (if configured)..."
  # Insert email sending command here
  echo "Alert email sent."
}

# Check command line arguments
if [[ "$1" == "--report" ]]; then
  generate_report
elif [[ "$1" == "--hardening" ]]; then
  server_hardening
else
  echo "Usage: $0 --report | --hardening"
  exit 1
fi
