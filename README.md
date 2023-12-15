# Best-Arch
My arch config

## Enable weekly fstrim

```bash
sudo systemctl enable fstrim.timer
```
## Enable parallel compilation and compression

Edit `/etc/makepkg.conf`:

- Add the following row (replace 7 with CPU threads-1): `MAKEFLAGS="-j7"`
- Edit the row saying `COMPRESSXZ=(xz -c -z -)` to `COMPRESSXZ=(xz -c -z - --threads=0)`
- `sudo pacman -S pigz` and edit the row saying `COMPRESSGZ=(gzip -c -f -n)` to `COMPRESSGZ=(pigz -c -f -n)`

## Intel GPU

### Intel GPU early kernel mode setting

Edit `/etc/mkinitcpio.conf`, add the following at the end of the `MODULES` array: `intel_agp i915`

**NOTE**: on some systems (Intel+AMD GPU) adding `intel_agp` can cause issues with resume from hibernation. [Reference](https://wiki.archlinux.org/title/Kernel_mode_setting#Early_KMS_start).


## Compress initramfs with lz4

Make sure `lz4` is installed.

Edit `/etc/mkinitcpio.conf`:

- Add `lz4 lz4_compress` to the `MODULES` list (delimited by `()`)
- Uncomment or add the line saying `COMPRESSION="lz4"`
- Add a line saying `COMPRESSION_OPTIONS="-9"`
- Add `shutdown` to the `HOOKS` list (delimited by `()`)

Run `sudo mkinitcpio -p linux` to apply the mkinitcpio.conf changes.

## Limit journald log size

Edit `/etc/systemd/journald.conf`:

- Uncomment `SystemMaxUse=` and append `200M` (or any size you like).

## Disable core dumps

To improve performance and save disk space.

Edit `/etc/systemd/coredump.conf`, under `[Coredump]` uncomment `Storage=external` and replace it with `Storage=none`. Then run `sudo systemctl daemon-reload`. This alone disables the saving of coredumps but they are still in memory.

If you want to disable core dumps completely add `* hard core 0` to `/etc/security/limits.conf`.

## Enable deep sleep suspension mode

Verify that you're using the inefficient `s2idle` sleep state before continuing:

```bash
cat /sys/power/mem_sleep
```

| Inefficient     | Efficient       |
|-----------------|-----------------|
| `[s2idle] deep` | `s2idle [deep]` |

Add `mem_sleep_default=deep` to the kernel command line arguments.

## Change IO Scheduler

## Change CPU governor

[Arch Wiki reference](https://wiki.archlinux.org/index.php/CPU_frequency_scaling)

```bash
sudo pacman -S cpupower
```

To change the governor for the current session run `sudo cpupower frequency-set -g performance`.

To change the governor on boot create a systemd service.

Create `/etc/systemd/system/cpupower.service`:

```
[Unit]
Description=Set CPU governor to performance

[Service]
Type=oneshot
ExecStart=/usr/bin/cpupower -c all frequency-set -g performance

[Install]
WantedBy=multi-user.target
```

Finally run `sudo systemctl enable cpupower.service`.

*NB: the default governor is powersave and you may want to leave it as it is.*

Create `/etc/udev/rules.d/50-scaling-governor.rules` as follows:

```
SUBSYSTEM=="module", ACTION=="add", KERNEL=="acpi_cpufreq", RUN+=" /bin/sh -c ' echo performance > /sys/devices/system/cpu/cpufreq/policy0/scaling_governor ' "
```


## Manage system resources for better performance

Create the script to optimize system memory and swap usage, freecache.sh:

```bash
#!/bin/bash
set -e

# --- // AUTO_ESCALATE:
if [ "$(id -u)" -ne 0 ]; then
    sudo "$0" "$@"
    exit $?
fi

# Logging function
log_action() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> /var/log/freecache.log
}

# Adjust swappiness dynamically based on system conditions
adjust_swappiness() {
    local current_swappiness=$(sysctl vm.swappiness | awk '{print $3}')
    local target_swappiness=60
    if [[ "$FREE_RAM" -lt 1000 ]]; then
        target_swappiness=80
    elif [[ "$FREE_RAM" -gt 2000 ]]; then
        target_swappiness=40
    fi
    if [[ "$current_swappiness" -ne "$target_swappiness" ]]; then
        sudo sysctl vm.swappiness="$target_swappiness"
        log_action "Swappiness adjusted to $target_swappiness"
    fi
}

# Clear RAM cache if needed
clear_ram_cache() {
    if [ "$FREE_RAM" -lt 500 ]; then
        sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
        log_action "RAM cache cleared due to low free memory."
    fi
}

# Clear swap if needed
clear_swap() {
    if [ "$SWAP_USAGE" -gt 80 ]; then
        sudo swapoff -a && sudo swapon -a
        log_action "Swap cleared due to high swap usage."
    fi
}

# Main logic
FREE_RAM=$(free -m | awk '/^Mem:/{print $4}')
SWAP_USAGE=$(free | awk '/^Swap:/{printf "%.0f", $3/$2 * 100}')

adjust_swappiness
clear_ram_cache
clear_swap

log_action "Memory and Swap Usage After Operations:"
free -h | tee -a /var/log/freecache.log
```

Create the monitoring script that will continuously check the system's free memory and update 'tmp/low_memory' when low.

```bash
#!/bin/bash
while true; do
    FREE_RAM=$(free -m | awk '/^Mem:/{print $4}')
    if [ "$FREE_RAM" -lt 500 ]; then
        touch /tmp/low_memory
    else
        rm -f /tmp/low_memory
    fi
    sleep 60  # Check every 60 seconds
done
```

Now the Systemd Service file for freecache.sh at /etc/systemd/system:

```
[Unit]
Description=Monitor Memory Usage

[Service]
Type=simple
ExecStart=/usr/local/bin/System_utilities/memory_monitor.sh

[Install]
WantedBy=multi-user.target
```

And its Path File at /etc/systemd/system:

```
[Unit]
Description=Monitor for Low Memory Condition

[Path]
PathExists=/tmp/low_memory

[Install]
WantedBy=multi-user.target
```

Service file for the monitoring script:

```
[Unit]
Description=Monitor Memory Usage

[Service]
Type=simple
ExecStart=/usr/local/bin/System_utilities/memory_monitor.sh

[Install]
WantedBy=multi-user.target
```

And finally, enable and start both the 'memory_monitor.service' and 'freecache.path':

```bash
sudo systemctl enable memory_monitor.service
sudo systemctl start memory_monitor.service
sudo systemctl enable freecache.path
sudo systemctl start freecache.path
```


## Setup Arch-Audit Timer for security

Create a new service file, `arch-audit.service`, in `/etc/systemd/system/`.

```bash
    `sudo nano /etc/systemd/system/arch-audit.service`
```

Add the following content to the file:

```bash
    `[Unit] Description=Arch Audit Vulnerability Checking Service
     [Service] Type=oneshot ExecStart=/usr/bin/arch-audit -u`
```

Create the Timer File

```bash
    `sudo nano /etc/systemd/system/arch-audit.timer`
```

Add the following content to the timer file:

```bash
    `[Unit] Description=Runs arch-audit daily
     [Timer] OnCalendar=daily Persistent=true
     [Install] WantedBy=timers.target`
```

Start the services

```bash
    `sudo systemctl daemon-reload`
    `sudo systemctl enable arch-audit.timer`
    `sudo systemctl start arch-audit.timer`

*   You can check the status of the timer with:

```bash
    `sudo systemctl status arch-audit.timer`
```

*   To see the next scheduled run:

```bash
    `sudo systemctl list-timers arch-audit.timer`
```


## Setting up Plymouth

*NOTE: this setup implies that you use paru (AUR helper), gdm (display manager), and the default arch kernel.*

```bash
paru -S plymouth-git gdm-plymouth
```

Edit `/etc/mkinitcpio.conf`:

- In `HOOKS` after `base udev` insert `plymouth`
- If you're using encryption, in `HOOKS` replace `encrypt` with `plymouth-encrypt`
- In `MODULES` insert your GPU driver module name as first item
  - For Intel GPUs: `i915`
  - For AMD GPUs: `radeon` *(note: this is untested)*
  - For NVIDIA GPUs: `nvidia` *(note: this is untested)*
  - For KVM/qemu VMs: `qxl`

Edit `/boot/loader/entries/arch-linux.conf`: add these arguments in the kernel options (append to the `options` section): `quiet splash loglevel=3 rd.udev.log_priority=3 vt.global_cursor_default=1`

```bash
sudo systemctl disable gdm
sudo systemctl enable gdm-plymouth
sudo mkinitcpio -p linux
```


### Copy monitor layout from user to GDM

GDM doesn't know how you configure your monitors. It just keep its default configuration and most of the time it's not the same of how you have them configured in your session.

To copy your user's monitors configuration over to GDM, use these commands:

```bash
sudo cp $HOME/.config/monitors.xml /var/lib/gdm/.config/
sudo chown gdm:gdm /var/lib/gdm/.config/monitors.xml
```


## Create a swap file

[Arch Wiki reference](https://wiki.archlinux.org/index.php/Swap#Swap_file)

A form of swap is required to enable hibernation.

In this example we will allocate a 8G swap file.

```bash
sudo dd if=/dev/zero of=/home/swapfile bs=1M count=8192
sudo chmod 600 /home/swapfile
sudo mkswap /home/swapfile
sudo swapon /home/swapfile # this enables the swap file for the current session
```

Edit `/etc/fstab` adding the following line:

```
/home/swapfile none swap defaults 0 0
```

### Removing the swap file if not necessary/wanted anymore

```
sudo swapoff -a
```

Edit `/etc/fstab` and remove the swapfile entry, and finally:

```
sudo rm -f /home/swapfile
```

### Alternative route

Use systemd-swap for automated and dynamic swapfile allocation and use. Consult [the GitHub project page](https://github.com/Nefelim4ag/systemd-swap) for more info.



## Create a cron tab to automatically free swap and ram cache

Make the script:

```bash
#!/bin/bash
# This command frees only RAM cache
#echo "echo 3 > /proc/sys/vm/drop_caches"
# This command frees RAM cache and swap
su -c "echo 3 >'/proc/sys/vm/drop_caches' && swapoff -a && swapon -a && printf '\n%s\n' 'Ram-cache and Swap Cleared'" root
```

Make it executable:
```
chmod 755 freecache
```

Make the crontab:
```
crontab -e
```
Append the below line, save and exit to run it at 2 am daily:
```

0  2  *  *  *  /usr/local/bin/freecache
```



## Enable Hibernation

[Arch Wiki reference](https://wiki.archlinux.org/index.php/Power_management/Suspend_and_hibernate#Hibernation_into_swap_file)

## Enable magic sysreq

Add this line to a file inside `/etc/sysctl.d/` (ie: `99-sysctl.conf`)

```
kernel.sysrq=1
```


# Package Management

## Switch to better mirrors

[Arch Wiki reference](https://wiki.archlinux.org/index.php/Reflector)

```bash
sudo pacman -S reflector
sudo reflector --latest 20 --protocol http --protocol https --sort rate --save /etc/pacman.d/mirrorlist
```

## Enable parallel compilation and compression

Edit `/etc/makepkg.conf`:

- Add the following row (replace 7 with CPU threads-1): `MAKEFLAGS="-j7"`
- Edit the row saying `COMPRESSXZ=(xz -c -z -)` to `COMPRESSXZ=(xz -c -z - --threads=0)`
- `sudo pacman -S pigz` and edit the row saying `COMPRESSGZ=(gzip -c -f -n)` to `COMPRESSGZ=(pigz -c -f -n)`

# Networking

## DNSCrypt

[Arch Wiki reference](https://wiki.archlinux.org/index.php/DNSCrypt)

Encrypt your DNS traffic so your ISP can't spy on you. Use `pdnsd` as a proxy and cache for it.

### Install

```bash
sudo pacman -S dnscrypt-proxy pdnsd
```

### Configure

Edit `/etc/dnscrypt-proxy/dnscrypt-proxy.toml`:

- Uncomment the `server_names` list (line 30) and change it as follows: `server_names = ['de.dnsmaschine.net', 'trashvpn']` (see *Note* below)
- Change the `listen_address` list (line 36) to an empty list: `listen_address = []` (we're using systemd socket, this avoids port conflicts)

*Note: you can find more "Resolvers" in `/usr/share/dnscrypt-proxy/dnscrypt-resolvers.csv` or [here](https://github.com/dyne/dnscrypt-proxy/blob/master/dnscrypt-resolvers.csv)*

Edit `/usr/lib/systemd/system/dnscrypt-proxy.service` to include the following:

```
[Service]
DynamicUser=yes
```

Edit `/usr/lib/systemd/system/dnscrypt-proxy.socket` to change the port dnscrypt runs on. Here is a snippet:

```
[Socket]
ListenStream=127.0.0.1:53000
ListenDatagram=127.0.0.1:53000
```

Create `/etc/pdnsd.conf` like so:

```
global {
	perm_cache=1024;
	cache_dir="/var/cache/pdnsd";
#	pid_file = /var/run/pdnsd.pid;
	run_as="pdnsd";
	server_ip = 127.0.0.1;  # Use eth0 here if you want to allow other
				# machines on your network to query pdnsd.
	status_ctl = on;
#	paranoid=on;       # This option reduces the chance of cache poisoning
	                   # but may make pdnsd less efficient, unfortunately.
	query_method=udp_tcp;
	min_ttl=15m;       # Retain cached entries at least 15 minutes.
	max_ttl=1w;        # One week.
	timeout=10;        # Global timeout option (10 seconds).
	neg_domain_pol=on;
	udpbufsize=1024;   # Upper limit on the size of UDP messages.
}

server {
    label = "dnscrypt-proxy";
    ip = 127.0.0.1;
    port = 53000;
    timeout = 4;
    proxy_only = on;
}

source {
	owner=localhost;
#	serve_aliases=on;
	file="/etc/hosts";
}

rr {
	name=localhost;
	reverse=on;
	a=127.0.0.1;
	owner=localhost;
	soa=localhost,root.localhost,42,86400,900,86400,86400;
}
```

Reload systemd daemons, enable and start services:

```bash
sudo systemctl daemon-reload
sudo systemctl enable dnscrypt-proxy.service pdnsd.service
sudo systemctl start dnscrypt-proxy.service pdnsd.service
```

Edit your NetworkManager configuration to point to the following IPs for respectively IPv4 and IPv6 DNSes:

```
127.0.0.1
::1
```

## MPV Custom .conf file (SVP4 NVIDIA VDPAU)

Install `nvidia-utils` (or similar package depending on your nvidia driver) and `libva-vdpau-driver`. Install SVP4.

Create or edit `.config/mpv/mpv.conf`:

```
vo=vdpau
profile=opengl-hq
hwdec=vdpau
hwdec-codecs=all
scale=ewa_lanczossharp
cscale=ewa_lanczossharp
interpolation
tscale=oversample
----------------
SVP CUSTOM SETTINGS
fs=yes
--screenshot-webp-lossless=yes
--override-display-fps=60
--loop-file=inf
no-resume-playback
geometry=50%:50%
autofit-larger=90%x90%
keep-open=yes
force-window=immediate
osc=no
ontop=yes
profile=gpu-hq
video-sync=display-resample
input-ipc-server=/tmp/mpvsocket
hwdec=auto-copy
hr-seek-framedrop=no
vo=xv
vo=vdpau=hqscaling=9
--no-correct-pts
hwdec-codecs=all
interpolation=yes
scale=ewa_lanczossharp
cscale=ewa_lanczossharp
tscale=oversample
gpu-context=wayland
osc=no
osd-bar=no
---------------
PLAY IN MPV SETTINGS
ontop=yes
border=no
window-scale=0.4
geometry=100%:100%
--------------------
demuxer-max-back-bytes=10000000000
demuxer-max-bytes=10000000000
interpolation=yes
sub-visibility=no
sub-auto=fuzzy
alang=en,eng,da,dan
slang=en,eng,da,dan
vlang=en,eng,da,dan
save-position-on-quit=yes
ignore-path-in-watch-later-config=yes
[extension.gif]
loop-file=inf
[extension.webm]
loop-file=inf
[extension.jpg]
pause
[extension.png]
pause
```


## Setup libvirt

```bash
sudo pacman -S libvirt ebtables dnsmasq bridge-utils virt-manager
sudo gpasswd -a $USERNAME libvirt
sudo gpasswd -a $USERNAME kvm
sudo systemctl enable libvirtd
sudo systemctl start libvirtd
```

Make sure to relogin after following the steps above. To create a network:

- Open virt-manager
- Click on *QEMU/KVM*
- Click *Edit > Connection Details* in the menu
- Click the *Virtual Networks* tab
- Click the `+` (plus sign) button in the bottom left corner of the newly opened window
- Name it whatever
- Select *NAT* as Mode
- Leave everything else as it is
- Click finish
- To start the network, select it in the sidebar and press the ▶️ (play icon) button
- To stop the network, press the icon to its left with the 🛑 (stop street sign icon) button (note: the icons could be different depending on the theme)
- To start the network on boot, select it in the sidebar and toggle the checkbox that says *Autostart: On Boot*

## GNOME Adwaita theme for Qt apps

- Install `qt5ct` from the repos and `adwaita-qt` from the AUR
- Open up the `qt5ct` application and select your favorite Adwaita flavor with the default color scheme and press apply
- Add the following to `~/.pam_environment`:

```
QT_QPA_PLATFORMTHEME=qt5ct
```

- Add the following to `~/.profile`:

```
[ "$XDG_CURRENT_DESKTOP" = "KDE" ] || export QT_QPA_PLATFORMTHEME="qt5ct"
```
