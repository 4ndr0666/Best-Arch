# Best Arch

## SSDs: Enable Weekly Filesystem Trim

To enable weekly filesystem trim on your SSDs, run the following command:

```bash
sudo systemctl enable fstrim.timer --now
```

### Explanation

- **Filesystem Trim**: This command schedules a weekly trim operation to remove blocks no longer in use by the filesystem, which helps maintain SSD performance over time.

---

## Make Timeouts & Reboots Faster

To reduce the timeouts and speed up reboots, edit the `etc/systemd/system.conf` file and adjust the following settings:

```ini
RebootWatchdogSec=10s
DefaultTimeoutStartSec=5s
DefaultTimeoutStopSec=5s
```

### Explanation

- **Reboot Speed**: These settings reduce the delay during system start, stop, and reboot processes, ensuring quicker transitions.

---

## Enable Parallel Compilation & Compression with Makepkg

To optimize the package building process, you can enable parallel compilation and compression by editing the `/etc/makepkg.conf` file:

1. **Parallel Compilation**:
    - Add the following line to utilize all but one CPU thread:

    ```bash
    MAKEFLAGS="-j$(nproc)"
    ```

    - Replace `$(nproc)` with your CPU's thread count minus one (e.g., `-j7` for an 8-thread CPU).

2. **Faster Compression with Pigz**:
    - Install `pigz` (Parallel Implementation of Gzip):

    ```bash
    sudo pacman -S pigz
    ```

    - Modify the compression settings:

   ```bash
    COMPRESSXZ=(xz -c -z - --threads=0)
    COMPRESSGZ=(pigz -c -f -n)
    ```

### Explanation

- **Parallel Compilation**: `MAKEFLAGS="-j$(nproc)"` tells `makepkg` to use multiple CPU cores during the build process, speeding up compilation.
- **Compression Settings**: Replacing `gzip` with `pigz` allows for parallel compression, which is significantly faster on multi-core processors.

After editing the file, the changes will take effect the next time you build a package using `makepkg`.

---

## GPU

### Intel GPU early kernel mode setting

Ensure the modules `intel_agp i915` are first in the `MODULES` array in `/etc/mkinitcpio.conf`.

Ensure `/etc/modprobe.d/i915.conf` exists. If not, create it with these values:

```bash
options i915 enable_guc=2
options i915 enable_fbc=1
```

```bash
sudo mkinitcpio -P
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

**NOTE**: on some systems (Intel+AMD GPU) adding `intel_agp` can cause issues with resume from hibernation. [Reference](https://wiki.archlinux.org/title/Kernel_mode_setting#Early_KMS_start).

### Fix screen tearing

Edit `/etc/X11/xorg.conf.d/`, add the following conf file: `20-intel.conf`

```bash
Section "Device"
     Identifier "Intel Graphics"
     Driver "intel"
     Option "TearFree" "true"
EndSection
```

```bash
sudo mkinitcpio -p linux
```

### Enable betterscreen suspend service

```bash
sudo systemctl enable betterlockscreen@${USER}.service
```

### AMD hwdec

```bash
sudo pacman -S libva-mesa-driver mesa-vdpau
```

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

```ini
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

```bash
SUBSYSTEM=="module", ACTION=="add", KERNEL=="acpi_cpufreq", RUN+=" /bin/sh -c ' echo performance > /sys/devices/system/cpu/cpufreq/policy0/scaling_governor ' "
```

## Manage system resources for better performance

Create the script to optimize system memory and swap usage, freecache.sh:

```bash
#!/bin/bash
set -e

# AUTO_ESCALATE
if [ "$(id -u)" -ne 0 ]; then
    sudo "$0" "$@"
    exit $?
fi

log_action() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> /var/log/freecache.log
}

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

clear_ram_cache() {
    if [ "$FREE_RAM" -lt 500 ]; then
        sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
        log_action "RAM cache cleared due to low free memory."
    fi
}

clear_swap() {
    if [ "$SWAP_USAGE" -gt 80    ]; then
        sudo swapoff -a && sudo swapon -a
        log_action "Swap cleared due to high swap usage."
    fi
}

FREE_RAM=$(free -m | awk '/^Mem:/{print $4}')
SWAP_USAGE=$(free | awk '/^Swap:/{printf "%.0f", $3/$2 * 100}')

adjust_swappiness
clear_ram_cache
clear_swap

log_action "Memory and Swap Usage After Operations:"
free -h | tee -a /var/log/freecache.log
```

Create the monitoring script that will continuously check the system's free memory and update \`/tmp/low_memory\` when low.

```bash
#!/bin/bash
while true; do
    FREE_RAM=$(free -m | awk '/^Mem:/{print $4}')
    # Adjust this threshold as needed, ensuring it's higher than oomd's threshold
    if [ "$FREE_RAM" -lt 1000 ]; then
        touch /tmp/low_memory
    else
        rm -f /tmp/low_memory
    fi
    sleep 60  # Check every 60 seconds
done
```

Now the Systemd Service file for `freecache.sh` at `/etc/systemd/system`:

```ini
[Unit]
Description=Free Cache when Memory is Low
After=oomd.service  # Ensures this service runs after oomd

[Service]
Type=oneshot
ExecStart=/usr/local/bin/System_utilities/freecache.sh

[Install]
WantedBy=multi-user.target
```

And its Path File at `/etc/systemd/system`:

```ini
[Unit]
Description=Monitor for Low Memory Condition

[Path]
PathExists=/tmp/low_memory

[Install]
WantedBy=multi-user.target
```

Service file for the monitoring script:

```ini
[Unit]
Description=Monitor Memory Usage

[Service]
Type=simple
ExecStart=/usr/local/bin/System_utilities/memory_monitor.sh

[Install]
WantedBy=multi-user.target
```

And finally, enable and start both the `memory_monitor.service` and `freecache.path`:

```bash
sudo systemctl enable memory_monitor.service
sudo systemctl start memory_monitor.service
sudo systemctl enable freecache.path
sudo systemctl start freecache.path
```

## Setup Arch-Audit Timer for security

Create a new service file, `arch-audit.service`, in `/etc/systemd/system/`.

```bash
sudo vim /etc/systemd/system/arch-audit.service
```

Add the following content to the file:

```ini
[Unit]
Description=Arch Audit Vulnerability Checking Service

[Service]
Type=oneshot
ExecStart=/usr/bin/arch-audit -u
```

Create the Timer File

```bash
sudo vim /etc/systemd/system/arch-audit.timer
```

Add the following content to the timer file:

```ini
[Unit]
Description=Runs arch-audit daily

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
```

Start the services

```bash
sudo systemctl daemon-reload
sudo systemctl enable arch-audit.timer
sudo systemctl start arch-audit.timer
```

- You can check the status of the timer with:

```bash
sudo systemctl status arch-audit.timer
```

- To see the next scheduled run:

```bash
sudo systemctl list-timers arch-audit.timer
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

```shell
/home/swapfile none swap defaults 0 0
```

### Removing the swap file if not necessary/wanted anymore

```bash
sudo swapoff -a
```

Edit `/etc/fstab` and remove the swapfile entry, and finally:

```bash
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
su -c "echo 3 > /proc/sys/vm/drop_caches && swapoff -a && swapon -a && printf '\n%s\n' 'Ram-cache and Swap Cleared'" root
```

Make it executable:

```bash
chmod 755 freecache
```

Make the crontab:

```bash
crontab -e
```

Append the below line, save and exit to run it at 2 am daily:

```shell
0  2  *  *  *  /usr/local/bin/freecache
```

## Enable Hibernation

[Arch Wiki reference](https://wiki.archlinux.org/index.php/Power_management/Suspend_and_hibernate#Hibernation_into_swap_file)

## Enable magic sysreq

Add this line to a file inside `/etc/sysctl.d/` (ie: `99-sysctl.conf`)

```shell
kernel.sysrq=1
```

## Package Management

### Switch to better mirrors

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

## Networking

### DNSCrypt

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

```ini
[Service]
DynamicUser=yes
```

Edit `/usr/lib/systemd/system/dnscrypt-proxy.socket` to change the port dnscrypt runs on. Here is a snippet:

```ini
[Socket]
ListenStream=127.0.0.1:53000
ListenDatagram=127.0.0.1:53000
```

Create `/etc/pdnsd.conf` like so:

```ini
global {
    perm_cache=1024;
    cache_dir="/var/cache/pdnsd";
    # pid_file = /var/run/pdnsd.pid;
    run_as="pdnsd";
    server_ip = 127.0.0.1;  # Use eth0 here if you want to allow other
                            # machines on your network to query pdnsd.
    status_ctl = on;
    # paranoid=on;       # This option reduces the chance of cache poisoning
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
    # serve_aliases=on;
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

```shell
127.0.0.1
::1
```

## Mpv

- Install the smooth video project or [SVP4](https://www.svp-team.com/wiki/SVP:Linux)

Ensure all i915 intel packages with:

```bash
yay --needed --noconfirm libva-intel-driver vulkan-intel libvdpau-va-gl lib32-vulkan-intel vulkan-intel libva-intel-driver libva-utils lib32-mesa mesa libva libva-mesa-driver libva-vdpau-driver libva-utils lib32-libva lib32-libva-intel-driver lib32-libva-mesa-driver lib32-libva-vdpau-driver intel-ucode iucode-tool vulkan-intel lib32-vulkan-intel intel-gmmlib intel-graphics-compiler intel-compute-runtime intel-gpu-tools intel-media-driver intel-media-sdk intel-opencl-clang libmfx
```

Create a new profile for SVP and add it to the config file. This is my completed mpv.conf file and here is how to add the svp profile.

- Edit  `~/.config/mpv/mpv.conf` to include the following:

```bash
## --- // MPV.CONF // ========

# --- // GENERAL_SETTINGS:
--loop-file=inf
--speed=0.50
#--profile=fast  # Profile "fast" can be re-enabled if quick startup and playback is prioritized
--video-output-levels=full
--sub-visibility=no
--input-ipc-server=/tmp/mpvsocket  # Re-enabled for use with SVP or other scripts that may require it
--hwdec=auto-copy  # Ensure hardware decoding is active, depending on your GPU and driver
#--hwdec=auto-safe  # This can be re-enabled if you experience issues with auto-copy

# --- // WAYLAND:
--wayland-app-id=Mpv
--wlshm

# --- // PLAYER_SETTINGS //
# The settings below are adjusted for flexibility with various content types
# Re-enable profiles as needed depending on your media type
#setpts=PTS*2
#no-correct-pts
#vd-lavc-dr=yes
#vd-lavc-assume-old-x264= yes
#user-agent=libmpv
--x11-bypass-compositor=no
--player-operation-mode=pseudo-gui
#rar-list-all-volumes= yes
#directory-mode=recursive
#corner-rounding=1
--save-position-on-quit  # Re-enabled to save playback positions across sessions

# --- // AUDIO_SETTINGS //
# --video-sync=desync
# --video-sync=display-resample
# --audio-device=
# --alsa/sysdefault:CARD=PCH
# audio-pitch-correction=no
# audio-channels=5.1
# audio-channels=auto
volume-max=250  # This setting has been retained, but ensure your volume requirements are met
#--no-audio  # Keep this disabled unless you specifically want to mute audio during playback

# --- // WINDOW //
--window-scale=0.500
--ontop=yes  # Ensure the player stays on top for focused viewing
--geometry=100%:100%  # This ensures the window scales properly across the full screen
# --geometry=50%:50%
# --video-rotate=<0-359|no>
# keepaspect=no
# --on-all-workspaces=yes
# --term-title=yes
# --title=${?media-title:${media-title}}-mpv
# --no-border
# --snap-window=yes
--stop-screensaver=always  # Retained for preventing the screensaver from interrupting playback
# --osd-blur=2
# --osd-border-size=1
# --osd-duration=8000
# --osd-on-seek=msg-bar
# --force-window=immediate
# --force-seekable=yes
# --display-tags=Title, Channel_URL, service_name
--autofit-larger=88%
# --autofit-larger=30%x30%
# --autofit-smaller=yes
# --geometry=50%+10+10/2
--keep-open=always  # Retained for keeping the player open after playback
--keep-open-pause=no
layout=slimbox  # Ensuring a minimalistic layout for better viewing experience
#seekbarstyle=diamond
#seekbarhandlesize=0.6
#seekbarkeyframes=no
#seekrangestyle=inverted
#seekrangeseparate=yes
#seekrangealpha=213
#minmousemove=3
#showwindowed=yes
#showfullscreen=yes
#idlescreen=yes
#scalewindowed=1.0
#scalefullscreen=1.0
#scaleforcedwindow=2.0
#vidscale=no

# --- // OSC //
# --script-opts=osc-layout=bottombar,osc-seekbarstyle=bar
--taskbar-progress=yes
# --term-title=yes
# --title=${?media-title:${media-title}}-mpv
# --osd-level=1
# --osd-bar=no
--osc=no  # Retained as per your preference; re-enable if you want on-screen controls
# term-status-msg="Time: ${time-pos}"

# --- // PROFILES //
vo=gpu  # General GPU acceleration; consider enabling specific profiles below depending on the content type
# --profile=svp

# --- // SVP_PROFILE:
# Enabled specific settings for SVP, tailored to smooth playback
[svp]
--input-ipc-server=/tmp/mpvsocket
--hwdec=auto-copy
--hr-seek=always
--hr-seek-framedrop=no
#--vf=format:colormatrix=bt.709  # Adjust this if you notice color issues
--no-resume-playback
--ignore-path-in-watch-later-config=yes
--opengl-early-flush=yes  # Retained for smoother playback with SVP

## VDPAU_PROFILE:
[vdpau]
# Enhanced settings for VDPAU (NVIDIA hardware acceleration)
# --hqscaling=9
# --scale=ewa_lanczossharp
# --scale=bilinear
# --cscale=bilinear
# --cscale=spline36
# --zimg-dither=error-diffusion
# --zimg-scaler=spline36
# --zimg-scaler-chroma=spline36
# --deband=yes
# --deinterlace=yes
# --interpolation=yes
# --interpolation-preserve=yes
# --linear-upscaling=yes
# --interpolation-threshold=0.03
# --tscale-param1=mitchell
# --tscale-param2=0.5
# --sws-scaler=lanczos
# --sws-fast=no
# --sws-allow-zimg=yes
# --zimg-fast=no
# --tone-mapping=bt.2390
# --tone-mapping-max-boost=3.0
# --gpu-dumb-mode=yes
# --gpu-context=wayland

# --- // EYE_CANCER_PROFILE:
# [eye-cancer]
# sharpen=5

# --- // PYRADIO:
# [pyradio]
# volume=50

# --- // WEB_BROWSER:
[Act as a web browser]
# Updated user-agent for better compatibility with streaming sites
user-agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:121.0) Gecko/20100101 Firefox/121.0"
# --cache=yes
# --demuxer-max-bytes=123400KiB
# --cache-pause=no
# --demuxer-readahead-secs=20

# --- // ANIME4K:
# [anime4k]
# --glsl-shaders=/usr/share/anime4k

# --- // Play_with_mpv:
# [play_with_mpv]
# ontop=yes
# border=no
# window-scale=0.4
# geometry=100%:100%

# --- // IMAGES //
--vo-image-format=png
--vo-image-png-compression=9
--vo-image-png-filter=5
--image-display-duration=inf

# --- // Screenshots:
--screenshot-format=png
--screenshot-png-compression=0
--screenshot-directory="~/Pictures/Screens"
--screenshot-template="%F - [%P]v%#01n"
# --screenshot-webp-lossless=yes
# --screenshot-webp-quality=100

# --- // Extension_behavior:
[extension.gif]
loop-file=inf

[extension.webm]
loop-file=inf

[extension.jpg]
--pause=yes

[extension.png]
--pause=yes
```

## Setup libvirt

```bash
sudo pacman -S libvirt ebtables dnsmasq bridge-utils virt-manager
sudo gpasswd -a ${USER} libvirt
sudo gpasswd -a ${USER} kvm
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

```bash
QT_QPA_PLATFORMTHEME=qt5ct
```

- Add the following to `~/.profile`:

```bash
[ "$XDG_CURRENT_DESKTOP" = "Openbox" ] || export QT_QPA_PLATFORMTHEME="qt5ct"
```

## Fonts

Edit `~/.Xresources`

```bash
Xft.dpi: 110
Xft.autohint: 0
Xft.lcdfilter:  lcdlegacy
Xft.hintstyle:  hintfull
Xft.hinting: 1
Xft.antialias: 1
Xft.rgba: rgb

! Style: nightfox
! Upstream: https://github.com/edeneast/nightfox.nvim/raw/main/extra/nightfox/nightfox.Xresources
*background: #192330
*foreground: #cdcecf
*color0:  #393b44
*color1:  #c94f6d
*color2:  #81b29a
*color3:  #dbc074
*color4:  #719cd6
*color5:  #9d79d6
*color6:  #63cdcf
*color7:  #dfdfe0
*color8:  #575860
*color9:  #d16983
*color10: #8ebaa4
*color11: #e0c989
*color12: #86abdc
*color13: #baa1e2
*color14: #7ad5d6
*color15: #e4e4e5
```
