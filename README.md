# Best-Arch
My arch config
##################
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
