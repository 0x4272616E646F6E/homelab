# Proxmox Baseline Configuration Playbook

This Ansible playbook provides comprehensive baseline configuration for Proxmox VE hypervisors with production-safe defaults, security hardening, monitoring, and optional feature flags.

## Features

✅ **Core Services**: DNS, NTP (chrony), syslog forwarding, NUT UPS monitoring  
✅ **Security**: Fail2Ban (SSH + Proxmox web UI), host-level ClamAV, rkhunter rootkit detection  
✅ **Automation**: Unattended security updates with safe defaults (no auto-reboot)  
✅ **Infrastructure**: Terraform Proxmox role/user provisioning, audit logging  
✅ **GPU Passthrough**: Driver blacklisting, IOMMU/VFIO configuration  
✅ **Monitoring**: pve_exporter for Prometheus metrics  
✅ **Optional**: SMTP relay (Postfix), ZFS tuning  

## Template Organization

Templates are organized by service in `templates/` folder:
```
templates/
  ├── audit/           # Audit rules for /etc/pve
  ├── cron/            # ClamAV and rkhunter daily scan scripts
  ├── fail2ban/        # Jail config and filters (SSH, Proxmox)
  │   └── filter.d/
  ├── logging/         # Rsyslog remote forwarding
  ├── network/         # DNS resolver config
  ├── nut/             # UPS monitoring configs (ups.conf, upsd.conf, etc.)
  ├── postfix/         # SMTP relay configuration
  ├── pve_exporter/    # Prometheus exporter systemd unit
  ├── timesync/        # Chrony NTP config
  └── unattended-upgrades/  # Auto-update configs
```

## Prerequisites

1. **Install Ansible collections:**
   ```bash
   ansible-galaxy collection install -r requirements.yml
   ```

2. **Configure SSH access to Proxmox hosts:**
   ```bash
   ssh-copy-id root@proxmox-host-ip
   ```

3. **Update inventory:**
   - Edit `inventories/production/hosts.yml` with your Proxmox host IPs
   - Edit `inventories/production/group_vars/proxmox.yml` with your settings

## Configuration Variables

Edit `inventories/production/group_vars/proxmox.yml`:

### DNS Servers
```yaml
dns_servers:
  - 10.0.0.1
```

### NTP Servers
```yaml
ntp_servers:
  - time.cloudflare.com
```

### Timezone
```yaml
timezone: "America/New_York"
```

### Syslog (Optional)
```yaml
syslog_enabled: true
syslog_server: "syslog.hosted.fail"
syslog_port: 514
syslog_protocol: "udp"
```

### NUT UPS Configuration

**For NUT Client Mode** (most common - UPS server is elsewhere):
```yaml
nut_enabled: true
nut_mode: "netclient"
nut_ups_name: "ups"
nut_monitor_user: "monuser"
nut_monitor_password: "secret"  # Change this!
nut_server: "192.168.1.1"
```

**For NUT Server Mode** (UPS is directly connected to this host):
```yaml
nut_enabled: true
nut_mode: "netserver"  # or "standalone"
nut_ups_name: "ups"
nut_ups_driver: "usbhid-ups"  # Check NUT compatibility list
nut_ups_port: "auto"
nut_monitor_user: "monuser"
nut_monitor_password: "secret" # Change this!
```

**Find your UPS driver:**
```bash
# On Proxmox host with UPS connected:
lsusb  # Find UPS USB device
nut-scanner -U  # Scan for UPS devices
```

Common drivers:
- `usbhid-ups` - Most modern USB UPS devices
- `snmp-ups` - Network UPS via SNMP
- `apcupsd-ups` - APC UPS with apcupsd
- `nutdrv_qx` - Megatec/Q1 protocol UPS

## Security: Encrypt Passwords

Use Ansible Vault to encrypt sensitive variables:

```bash
# Create encrypted vars file
ansible-vault create inventories/group_vars/proxmox_vault.yml
```

Add to `proxmox_vault.yml`:
```yaml
---
nut_monitor_password: "your_secure_password"
```

Update `proxmox.yml` to reference vault variable:
```yaml
nut_monitor_password: "{{ vault_nut_monitor_password }}"
```

Run playbook with vault:
```bash
ansible-playbook -i inventories/production playbook_proxmox.yml --ask-vault-pass
```

### Proxmox Terraform user/role

The playbook can create a Proxmox role and user for Terraform automation. Configure these variables in `inventories/group_vars/proxmox.yml` (store passwords in Ansible Vault):

```yaml
terraform_prov_role_name: "TerraformProv"
terraform_prov_role_privs: "Datastore.AllocateSpace Datastore.AllocateTemplate Datastore.Audit Pool.Allocate Sys.Audit Sys.Console Sys.Modify VM.Allocate VM.Audit VM.Clone VM.Config.CDROM VM.Config.Cloudinit VM.Config.CPU VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.Migrate VM.PowerMgmt SDN.Use"
terraform_prov_username: "terraform-prov@pve"
terraform_prov_user_password: "{{ vault_terraform_prov_password }}"  # store this in the vault
```

The playbook will:
- Create the role if it does not exist
- Create the user (requires `terraform_prov_user_password` to be set)
- Bind the role to the user at `/` with the appropriate ACL

If you prefer to manage the Proxmox user/role manually, leave `terraform_prov_user_password` empty and the playbook will skip user creation.

## Usage

### Dry Run (Check Mode)
```bash
ansible-playbook -i inventories/production playbook_proxmox.yml --check --diff
```

### Apply Configuration
```bash
ansible-playbook -i inventories/production playbook_proxmox.yml
```

### Run specific tags (future enhancement)
```bash
# Only configure DNS
ansible-playbook -i inventories/production playbook_proxmox.yml --tags dns

# Only configure NUT
ansible-playbook -i inventories/production playbook_proxmox.yml --tags nut
```

### Test connectivity
```bash
ansible -i inventories/production proxmox -m ping
```

## What This Playbook Does

### 1. Timezone Configuration
- Sets system timezone
- Restarts time synchronization service

### 2. DNS Configuration
- Updates `/etc/resolv.conf` with specified DNS servers
- Adds timeout and retry options

### 3. NTP Time Synchronization
- Installs and configures chrony
- Configures multiple NTP servers for redundancy
- Enables time sync on boot

### 4. Remote Syslog (Optional)
- Configures rsyslog to forward logs to remote server
- Supports UDP/TCP protocols

### 5. NUT UPS Monitoring (Optional)
- Installs NUT client/server
- Configures for standalone, server, or client mode
- Sets up monitoring and alerts

### 6. Proxmox Repository Configuration
- Disables enterprise repository warning
- Adds no-subscription repository
- Optionally adds `non-free-firmware` component

### 7. Unattended-Upgrades (Optional)
- Installs automatic security updates
- Configures Debian security updates only by default
- Blacklists critical packages (kernel, Proxmox core, Ceph, ZFS)
- **Auto-reboot disabled by default** (production-safe)
- Configurable email notifications

### 8. GPU Passthrough (Optional)
- Blacklists host GPU drivers for PCIe passthrough to VMs
- Configures NVIDIA, AMD, Intel drivers
- Configures IOMMU kernel parameters (Intel/AMD auto-detected)
- Updates GRUB and initramfs
- **Requires reboot to take effect**

### 9. Terraform Proxmox User/Role (Optional)
- Creates Terraform provisioning role with appropriate privileges
- Creates user account for Terraform authentication
- Assigns ACL at root path

### 10. Fail2Ban (Optional)
- Installs Fail2Ban
- Configures SSH and Proxmox web UI protection
- Custom filter for `pvedaemon` authentication failures
- Restarts service when configs change

### 11. SMTP Relay (Optional)
- Installs and configures Postfix as relay
- Supports TLS and SASL authentication
- Runs `postmap` for credential hashing

### 12. ZFS Tuning (Optional)
- Deploys ZFS kernel module tunables
- Configurable ARC min/max, aggregation limits

### 13. Host Antivirus (Optional)
- Installs ClamAV and freshclam
- Deploys daily scan cron script
- Updates signatures before scanning
- Logs to `/var/log/clamav-host-scan.log`

### 14. Rootkit Detection (Optional)
- Installs rkhunter
- Deploys daily update+scan cron script
- Logs to `/var/log/rkhunter-daily.log`

### 15. Prometheus Exporter (Optional)
- Installs pve_exporter (apt or binary fallback)
- Deploys systemd unit
- Exposes Proxmox metrics for Prometheus

### 16. Audit Logging (Optional)
- Deploys audit rule to watch `/etc/pve`
- Reloads audit rules via `augenrules`
- Restarts auditd service

## NUT UPS Testing

After running the playbook, test NUT:

### On NUT Server (if running netserver mode):
```bash
# Check UPS detection
upsdrvctl start

# Check UPS status
upsc ups@localhost

# View UPS variables
upsc ups@localhost battery.charge
upsc ups@localhost input.voltage
```

### On NUT Client:
```bash
# Check connection to server
upsc ups@nut-server-ip

# Check monitoring status
systemctl status nut-monitor

# Test communication
upsmon -c fsd  # Force shutdown (WARNING: use with caution!)
```

## Troubleshooting

### DNS not applying
Check if systemd-resolved is managing DNS:
```bash
systemctl status systemd-resolved
```
If active, you may need to disable it or configure via networkd.

### NTP not syncing
```bash
# Check chrony status
chronyc tracking

# Force sync
chronyc makestep

# Check sources
chronyc sources
```

### NUT not connecting
```bash
# Check NUT logs
journalctl -u nut-server -f
journalctl -u nut-monitor -f

# Test UPS driver
upsdrvctl start ups

# Check if upsd is listening
netstat -tuln | grep 3493
```

### UPS driver issues
```bash
# List available drivers
ls /lib/nut/

# Test driver manually
/lib/nut/usbhid-ups -a ups -DDDDD
```

### GPU Passthrough not working
```bash
# Check if modules are blacklisted
lsmod | grep -E 'nvidia|nouveau|amdgpu|radeon|i915|xe'

# Should return nothing if blacklist is working
# If modules are loaded, check blacklist file
cat /etc/modprobe.d/pve-blacklist.conf

# Verify initramfs was updated
ls -lah /boot/initrd.img-*

# Force update if needed
update-initramfs -u -k all

# Check kernel boot parameters (should include iommu)
cat /proc/cmdline

# Reboot required for GPU passthrough changes
reboot
```

### Unattended-upgrades not running
```bash
# Test what would be upgraded
unattended-upgrades --dry-run --debug

# Check logs
tail -f /var/log/unattended-upgrades/unattended-upgrades.log

# Check configuration
apt-config dump APT::Periodic
apt-config dump Unattended-Upgrade

# Manually trigger upgrade
unattended-upgrades --debug
```

## Files Created/Modified

### Core Services
- `/etc/resolv.conf` - DNS configuration
- `/etc/chrony/chrony.conf` - NTP configuration
- `/etc/rsyslog.d/50-remote.conf` - Syslog forwarding (if enabled)
- `/etc/nut/nut.conf` - NUT mode configuration
- `/etc/nut/upsmon.conf` - UPS monitoring (client)
- `/etc/nut/ups.conf` - UPS definitions (server)
- `/etc/nut/upsd.conf` - NUT server configuration (server mode)
- `/etc/nut/upsd.users` - NUT users (server mode)

### Security & Monitoring
- `/etc/fail2ban/jail.local` - Fail2Ban jail configuration
- `/etc/fail2ban/filter.d/proxmox.conf` - Proxmox-specific filter
- `/etc/cron.daily/clamav-host-scan` - Daily ClamAV scan script
- `/etc/cron.daily/rkhunter-update-scan` - Daily rkhunter scan script
- `/etc/audit/rules.d/90-pve.rules` - Audit rules for /etc/pve
- `/etc/systemd/system/pve_exporter.service` - Prometheus exporter unit

### Updates & Repositories
- `/etc/apt/sources.list.d/pve-no-subscription.list` - Proxmox repo
- `/etc/apt/apt.conf.d/20auto-upgrades` - Automatic update frequency
- `/etc/apt/apt.conf.d/50unattended-upgrades` - Unattended-upgrades configuration

### GPU Passthrough
- `/etc/modprobe.d/pve-blacklist.conf` - GPU driver blacklist for passthrough
- `/etc/default/grub` - IOMMU kernel parameters (updated by playbook)

### Optional
- `/etc/postfix/main.cf` - Postfix SMTP relay (if smtp_relay_enabled)
- `/etc/postfix/sasl_passwd` - SMTP auth credentials (if smtp_relay_auth)
- `/etc/modprobe.d/99-zfs-tuning.conf` - ZFS tunables (if zfs_tuning_enabled)

## GPU Passthrough Configuration

The playbook configures GPU passthrough by blacklisting host drivers. This is required for PCIe passthrough to VMs.

### Default Blacklisted Modules
- **NVIDIA**: nvidiafb, nouveau, nvidia, nvidia_drm, nvidia_modeset
- **AMD**: radeon, amdgpu
- **Intel**: i915, xe
- **Audio**: snd_hda_codec_hdmi, snd_hda_intel, snd_hda_codec, snd_hda_core

### IOMMU Configuration
In addition to driver blacklist, you need IOMMU enabled in GRUB:

1. Edit `/etc/default/grub` (manual step - not automated):
   ```bash
   # For Intel CPUs
   GRUB_CMDLINE_LINUX_DEFAULT="quiet intel_iommu=on iommu=pt"
   
   # For AMD CPUs
   GRUB_CMDLINE_LINUX_DEFAULT="quiet amd_iommu=on iommu=pt"
   ```

2. Update GRUB:
   ```bash
   update-grub
   reboot
   ```

3. Verify IOMMU is enabled:
   ```bash
   dmesg | grep -e DMAR -e IOMMU
   ```

### After Playbook Runs
**REBOOT REQUIRED** for GPU passthrough to take effect!

```bash
# Verify modules are NOT loaded
lsmod | grep -E 'nvidia|nouveau|amdgpu|radeon|i915|xe'

# Should return nothing if successful
```

## Integration with Homelab

This playbook ensures your Proxmox hosts have consistent baseline configuration that supports your Talos Kubernetes cluster running on VMs. The NUT configuration is especially important for graceful shutdown of VMs during power events.

**Key integrations**:
- **Monitoring**: `pve_exporter` provides Proxmox metrics to Prometheus running in your Kubernetes cluster
- **Logging**: Rsyslog forwards host logs to your centralized Loki/syslog server
- **Security**: Fail2Ban, ClamAV, and rkhunter protect the hypervisor layer
- **Automation**: Terraform user/role enables IaC-based VM provisioning
- **Audit**: Audit logs track changes to Proxmox cluster configuration in `/etc/pve`

## Security Best Practices

### Use Ansible Vault for Secrets

**Never commit plain-text passwords!** Store all secrets in Ansible Vault:

```bash
# Create vault file
ansible-vault create inventories/group_vars/proxmox_vault.yml
```

Add to `proxmox_vault.yml`:
```yaml
---
vault_nut_monitor_password: "your_secure_password"
vault_terraform_prov_password: "terraform_user_password"
vault_smtp_password: "smtp_relay_password"
```

Reference in `proxmox.yml`:
```yaml
nut_monitor_password: "{{ vault_nut_monitor_password }}"
terraform_prov_user_password: "{{ vault_terraform_prov_password }}"
smtp_relay_password: "{{ vault_smtp_password }}"
```

Run with vault:
```bash
ansible-playbook -i inventories/production playbook_proxmox.yml --ask-vault-pass
```

### Recommended Variable Checklist

Before deploying, review these variables in `group_vars/proxmox.yml`:

**Critical (Review First)**:
- [ ] `dns_servers` - Set to your internal DNS
- [ ] `ntp_servers` - Set to reliable NTP sources
- [ ] `timezone` - Match your location
- [ ] `unattended_upgrades_auto_reboot: false` - **Keep disabled for hypervisors!**
- [ ] `terraform_prov_user_password` - Store in Vault if using Terraform

**Security (Enable as Needed)**:
- [ ] `fail2ban_enabled: true` - Recommended for internet-facing hosts
- [ ] `host_antivirus_enabled: true` - Consider for production
- [ ] `rkhunter_enabled: true` - Lightweight rootkit detection
- [ ] `audit_pve_rules_enabled: true` - Track Proxmox config changes

**Monitoring (Enable for Production)**:
- [ ] `pve_exporter_enabled: true` - Required for Prometheus metrics
- [ ] `syslog_enabled: true` - Centralized logging

**Optional Enhancements**:
- [ ] `smtp_relay_enabled: true` - Email notifications
- [ ] `zfs_tuning_enabled: true` - If using ZFS storage

## Next Steps After Initial Deployment

1. **Verify services are running**:
   ```bash
   systemctl status chrony fail2ban nut-monitor
   ```

2. **Check Fail2Ban bans**:
   ```bash
   fail2ban-client status sshd
   ```

3. **Verify ClamAV updates**:
   ```bash
   freshclam
   ```

4. **Test Prometheus metrics** (if enabled):
   ```bash
   curl http://127.0.0.1:9221/pve
   ```

5. **Review logs**:
   ```bash
   tail -f /var/log/clamav-host-scan.log
   tail -f /var/log/rkhunter-daily.log
   journalctl -u fail2ban -f
   ```

6. **Reboot if GPU passthrough or IOMMU enabled**:
   ```bash
   reboot
   ```

## Maintenance

### Update ClamAV Signatures
```bash
freshclam
```

### Update rkhunter Database
```bash
rkhunter --update
rkhunter --propupd  # After system updates
```

### Check Fail2Ban Status
```bash
fail2ban-client status
fail2ban-client get sshd banned
```

### Review Audit Logs
```bash
ausearch -k pve -i  # Human-readable format
```

### Test Unattended-Upgrades
```bash
unattended-upgrades --dry-run --debug
```

## Troubleshooting

### Fail2Ban Issues
```bash
# Check status
fail2ban-client status

# View jail logs
journalctl -u fail2ban -f

# Test filter
fail2ban-regex /var/log/auth.log /etc/fail2ban/filter.d/sshd.conf

# Unban IP
fail2ban-client set sshd unbanip <IP>
```

### ClamAV Not Updating
```bash
# Check freshclam status
systemctl status clamav-freshclam

# Manual update
freshclam --verbose

# Check proxy settings if behind firewall
cat /etc/clamav/freshclam.conf
```

### pve_exporter Not Starting
```bash
# Check logs
journalctl -u pve_exporter -f

# Verify binary exists
ls -la /usr/local/bin/pve_exporter

# Check listen address
ss -tlnp | grep 9221
```

### New optional features added

#### Fail2Ban (SSH + Proxmox Web UI Protection)

Enable by setting in `inventories/group_vars/proxmox.yml`:

```yaml
fail2ban_enabled: true
fail2ban_ignore_ip:
  - 127.0.0.1
  - 192.168.1.0/24  # Add your trusted networks
fail2ban_maxretry: 3
fail2ban_findtime: "2h"
fail2ban_bantime: "1h"
```

The playbook will:
- Install Fail2Ban
- Deploy jail configuration for SSH (`/var/log/auth.log`) and Proxmox web UI (`pvedaemon` logs)
- Create a custom Proxmox filter at `/etc/fail2ban/filter.d/proxmox.conf`
- Restart Fail2Ban when configs change

**Jails configured**:
- `[sshd]` - Monitors SSH login attempts via systemd backend
- `[proxmox]` - Monitors Proxmox web UI authentication failures (ports 8006, https, http)

**Test Fail2Ban**:
```bash
# Check status
fail2ban-client status

# Check specific jail
fail2ban-client status sshd
fail2ban-client status proxmox

# View banned IPs
fail2ban-client get sshd banip
```

#### Host-Level Antivirus (ClamAV)

Enable by setting:

```yaml
host_antivirus_enabled: true
host_antivirus_scan_paths:
  - /var/lib/vz       # VM images and containers
  - /srv              # Custom data
  - /etc              # Configuration files
clamav_freshclam_update: true
clamav_scan_opts: "--recursive --infected --bell"
```

The playbook will:
- Install `clamav` and `clamav-freshclam`
- Deploy a daily cron script to `/etc/cron.daily/clamav-host-scan`
- Update virus signatures before scanning (if `clamav_freshclam_update: true`)
- Log results to `/var/log/clamav-host-scan.log`

**Manually trigger scan**:
```bash
/etc/cron.daily/clamav-host-scan
```

#### Rootkit Detection (rkhunter)

Enable by setting:

```yaml
rkhunter_enabled: true
rkhunter_update_databases: true
rkhunter_scan_opts: "--checkall"
```

The playbook will:
- Install `rkhunter`
- Deploy a daily update+scan script to `/etc/cron.daily/rkhunter-update-scan`
- Update rkhunter databases before scanning
- Log results to `/var/log/rkhunter-daily.log`

**After first install, run**:
```bash
rkhunter --propupd  # Initialize file property database
```

#### Proxmox Exporter for Prometheus

Enable by setting:

```yaml
pve_exporter_enabled: true
pve_exporter_version: "latest"  # or pin to specific version
pve_exporter_listen_address: "127.0.0.1:9221"
```

The playbook will:
- Try to install `pve-exporter` from apt
- Fall back to downloading binary from GitHub if package not available
- Deploy systemd unit at `/etc/systemd/system/pve_exporter.service`
- Expose metrics at `http://<listen_address>/pve` for Prometheus scraping

**Check metrics**:
```bash
curl http://127.0.0.1:9221/pve
```

#### Audit Logging for /etc/pve

Enable by setting:

```yaml
audit_pve_rules_enabled: true
audit_pve_rules_path: /etc/audit/rules.d/90-pve.rules
audit_pve_watch_path: /etc/pve
```

The playbook will:
- Deploy audit rule to monitor `/etc/pve` for write/attribute changes
- Reload audit rules via `augenrules --load`
- Restart auditd service

**View audit logs**:
```bash
ausearch -k pve  # Search for pve-tagged events
auditctl -l | grep pve  # Verify rule is active
```

#### SMTP Relay / Postfix (optional)

Enable by setting:

```yaml
smtp_relay_enabled: true
smtp_relay_host: "smtp.relay.example"
smtp_relay_port: 587
smtp_relay_use_tls: true
smtp_relay_auth: true
smtp_relay_user: "relay-user"
smtp_relay_password: "{{ vault_smtp_password }}"  # Store in Ansible Vault
```

The playbook will:
- Install and configure Postfix as a relay
- Deploy `/etc/postfix/main.cf`
- If auth enabled, deploy `/etc/postfix/sasl_passwd` and run `postmap`
- Restart Postfix

**Test email**:
```bash
echo "Test email" | mail -s "Proxmox test" user@example.com
```

#### ZFS Tuning (optional)

   Enable by setting:

   ```yaml
   zfs_tuning_enabled: true
   zfs_tuning:
      zfs_arc_max: "4G"
      zfs_arc_min: "1G"
      zfs_vdev_aggregation_limit: 4
   ```

   The playbook will write a simple ZFS tunables file; adjust values for your hardware. Reboot or reload ZFS modules as appropriate for your setup.
