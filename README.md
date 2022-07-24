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

## Enable Hibernation

[Arch Wiki reference](https://wiki.archlinux.org/index.php/Power_management/Suspend_and_hibernate#Hibernation_into_swap_file)

# Package Management

## Switch to better mirrors

[Arch Wiki reference](https://wiki.archlinux.org/index.php/Reflector)

```bash
sudo pacman -S reflector
sudo reflector --latest 200 --protocol http --protocol https --sort rate --save /etc/pacman.d/mirrorlist
```

## Enable colors in pacman

Edit `/etc/pacman.conf` and uncomment the row saying `Color`

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
```
##################
# video settings #
##################

# Start in fullscreen mode by default.
#fs=yes

#Screenshot upgrade
--screenshot-webp-lossless=yes

#Upscale fps
#--override-display-fps=60

#Repeat
--loop-file=inf 

#No resume
no-resume-playback

# force starting with centered window
geometry=50%:50%

# don't allow a new window to have a size larger than 90% of the screen size
autofit-larger=90%x90%

# Do not close the window on exit.
keep-open=yes

# Do not wait with showing the video window until it has loaded. (This will
# resize the window once video is loaded. Also always shows a window with
# audio.)
force-window=immediate

# Disable the On Screen Controller (OSC).
#osc=no

# Keep the player window on top of all other windows.
#ontop=yes

# Specify high quality video rendering preset (for --vo=gpu only)
# Can cause performance problems with some drivers and GPUs.
#profile=gpu-hq

# Force video to lock on the display's refresh rate, and change video and audio
# speed to some degree to ensure synchronous playback - can cause problems
# with some drivers and desktop environments.
#video-sync=display-resample

# Enable hardware decoding if available. Often, this does not work with all
# video outputs, but should work well with default settings on most systems.
# If performance or energy usage is an issue, forcing the vdpau or vaapi VOs
# may or may not help.
input-ipc-server=/tmp/mpvsocket
hwdec=auto-copy
hr-seek-framedrop=no
#vo=xv
#vo=vdpau=hqscaling=9
#--no-correct-pts
hwdec-codecs=all
#interpolation=yes
#scale=ewa_lanczossharp
#cscale=ewa_lanczossharp
#tscale=oversample
#gpu-context=wayland



###################
#test#############
#################
osc=no
osd-bar=no

####Play in mpv###
#ontop=yes
#border=no
#window-scale=0.4
#geometry=100%:100%
##################


#demuxer-max-back-bytes=10000000000
#demuxer-max-bytes=10000000000

#interpolation=yes

sub-visibility=no
sub-auto=fuzzy
alang=en,eng,da,dan
slang=en,eng,da,dan
vlang=en,eng,da,dan

#save-position-on-quit=yes
ignore-path-in-watch-later-config=yes

[extension.gif]
loop-file=inf

[extension.webm]
loop-file=inf

[extension.jpg]
pause

[extension.png]
pause
##################
# audio settings #
##################

# Specify default audio device. You can list devices with: --audio-device=help
# The option takes the device string (the stuff between the '...').
#audio-device=alsa/default

# Do not filter audio to keep pitch when changing playback speed.
#audio-pitch-correction=no

# Output 5.1 audio natively, and upmix/downmix audio with a different format.
#audio-channels=5.1
# Disable any automatic remix, _if_ the audio output accepts the audio format.
# of the currently played file. See caveats mentioned in the manpage.
# (The default is "auto-safe", see manpage.)
#audio-channels=auto
volume-max=250
##################
# other settings #
##################

# Pretend to be a web browser. Might fix playback with some streaming sites,
# but also will break with shoutcast streams.
#user-agent="Mozilla/5.0"

# cache settings
#
# Use 150MB input cache by default. The cache is enabled for network streams only.
#cache-default=153600
#
# Use 150MB input cache for everything, even local files.
#cache=153600
#
# Disable the behavior that the player will pause if the cache goes below a
# certain fill size.
#cache-pause=no
#
# Read ahead about 5 seconds of audio and video packets.
#demuxer-readahead-secs=5.0
#
# Raise readahead from demuxer-readahead-secs to this value if a cache is active.
#cache-secs=50.0

# Display English subtitles if available.
#slang=en

# Play Finnish audio if available, fall back to English otherwise.
#alang=fi,en

# Change subtitle encoding. For Arabic subtitles use 'cp1256'.
# If the file seems to be valid UTF-8, prefer UTF-8.
# (You can add '+' in front of the codepage to force it.)
#sub-codepage=cp1256

# You can also include other configuration files.
#include=/path/to/the/file/you/want/to/include

############
# Profiles #
############

# The options declared as part of profiles override global default settings,
# but only take effect when the profile is active.

# The following profile can be enabled on the command line with: --profile=eye-cancer

#[eye-cancer]
#sharpen=5

#keepaspect=no
#save-position-on-quit
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
