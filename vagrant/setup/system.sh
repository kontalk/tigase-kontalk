#!/bin/bash

source setup/functions.sh

# ### Set time zone
echo "Setting time zone to ${TIMEZONE}"
echo ${TIMEZONE} > /etc/timezone


# ### Setup a swap file
if [ -n "${SWAPSIZE}" ]; then
    SWAPFILE=/swapfile

    if [ -f "${SWAPFILE}" ]; then
        echo "Swap space already set"
    else
        echo "Setting up swap space"
        hide_output fallocate --length ${SWAPSIZE} ${SWAPFILE}
        hide_output mkswap ${SWAPFILE}
        hide_output chmod 0600 ${SWAPFILE}
        hide_output swapon ${SWAPFILE}

        # configure fstab
        grep -q "/swapfile" /etc/fstab ||
        echo "/swapfile none swap sw 0 0" >>/etc/fstab
    fi
fi


# ### Update Packages

# Update system packages to make sure we have the latest upstream versions of things from Ubuntu.

echo "Updating system"
hide_output apt-get update
apt_get_quiet dist-upgrade

# ### Install System Packages

# Install basic utilities.
#
# * haveged: Provides extra entropy to /dev/random so it doesn't stall
#	         when generating random numbers for private keys (e.g. during
#	         ldns-keygen).
# * unattended-upgrades: Apt tool to install security updates automatically.
# * cron: Runs background processes periodically.
# * ntp: keeps the system time correct
# * fail2ban: scans log files for repeated failed login attempts and blocks the remote IP at the firewall
# * netcat-openbsd: `nc` command line networking tool
# * git: we install some things directly from github
# * sudo: allows privileged users to execute commands as root without being root
# * coreutils: includes `nproc` tool to report number of processors, mktemp
# * bc: allows us to do math to compute sane defaults

echo "Installing system packages"
apt_install python3 python3-dev python3-pip \
    netcat-openbsd wget curl git sudo coreutils bc \
    vim vim-scripts htop haveged \
    unattended-upgrades cron ntp fail2ban

# ### Seed /dev/urandom
#
# /dev/urandom is used by various components for generating random bytes for
# encryption keys and passwords:
#
# * TLS private key (see `ssl.sh`, which calls `openssl genrsa`)
# * DNSSEC signing keys (see `dns.sh`)
# * our management server's API key (via Python's os.urandom method)
# * Roundcube's SECRET_KEY (`webmail.sh`)
# * ownCloud's administrator account password (`owncloud.sh`)
#
# Why /dev/urandom? It's the same as /dev/random, except that it doesn't wait
# for a constant new stream of entropy. In practice, we only need a little
# entropy at the start to get going. After that, we can safely pull a random
# stream from /dev/urandom and not worry about how much entropy has been
# added to the stream. (http://www.2uo.de/myths-about-urandom/) So we need
# to worry about /dev/urandom being seeded properly (which is also an issue
# for /dev/random), but after that /dev/urandom is superior to /dev/random
# because it's faster and doesn't block indefinitely to wait for hardware
# entropy. Note that `openssl genrsa` even uses `/dev/urandom`, and if it's
# good enough for generating an RSA private key, it's good enough for anything
# else we may need.
#
# Now about that seeding issue....
#
# /dev/urandom is seeded from "the uninitialized contents of the pool buffers when
# the kernel starts, the startup clock time in nanosecond resolution,...and
# entropy saved across boots to a local file" as well as the order of
# execution of concurrent accesses to /dev/urandom. (Heninger et al 2012,
# https://factorable.net/weakkeys12.conference.pdf) But when memory is zeroed,
# the system clock is reset on boot, /etc/init.d/urandom has not yet run, or
# the machine is single CPU or has no concurrent accesses to /dev/urandom prior
# to this point, /dev/urandom may not be seeded well. After this, /dev/urandom
# draws from the same entropy sources as /dev/random, but it doesn't block or
# issue any warnings if no entropy is actually available. (http://www.2uo.de/myths-about-urandom/)
# Entropy might not be readily available because this machine has no user input
# devices (common on servers!) and either no hard disk or not enough IO has
# ocurred yet --- although haveged tries to mitigate this. So there's a good chance
# that accessing /dev/urandom will not be drawing from any hardware entropy and under
# a perfect-storm circumstance where the other seeds are meaningless, /dev/urandom
# may not be seeded at all.
#
# The first thing we'll do is block until we can seed /dev/urandom with enough
# hardware entropy to get going, by drawing from /dev/random. haveged makes this
# less likely to stall for very long.

echo "Initializing system random number generator"
dd if=/dev/random of=/dev/urandom bs=1 count=32 2> /dev/null

# ### Package maintenance
#
# Allow apt to install system updates automatically every day.

cat > /etc/apt/apt.conf.d/02periodic <<EOF
APT::Periodic::MaxAge "7";
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::Verbose "1";
EOF

# ### Firewall

# Various virtualized environments like Docker and some VPSs don't provide
# a kernel that supports iptables. To avoid error-like output in these cases,
# we skip this if the user sets DISABLE_FIREWALL=1.
if [ -z "${DISABLE_FIREWALL}" ]; then
    echo "Installing firewall"

    # Install `ufw` which provides a simple firewall configuration.
    apt_install ufw

    # Allow incoming connections to SSH.
    ufw_allow ssh;

    # ssh might be running on an alternate port. Use sshd -T to dump sshd's
    # settings, find the port it is supposedly running on, and open that port
    # too.
    _SSH_PORT=$(sshd -T 2>/dev/null | grep "^port " | sed "s/port //")
    if [ ! -z "$_SSH_PORT" ]; then
    if [ "$_SSH_PORT" != "22" ]; then

    echo "Opening alternate SSH port ${_SSH_PORT}"
    ufw_allow ${_SSH_PORT}

    fi
    fi

    ufw --force enable;
fi

# ### Local DNS Service

# Install a local DNS server, rather than using the DNS server provided by the
# ISP's network configuration.
#
# We do this to ensure that DNS queries
# that *we* make (i.e. looking up other external domains) perform DNSSEC checks.
# We could use Google's Public DNS, but we don't want to create a dependency on
# Google per our goals of decentralization. `bind9`, as packaged for Ubuntu, has
# DNSSEC enabled by default via "dnssec-validation auto".
#
# So we'll be running `bind9` bound to 127.0.0.1 for locally-issued DNS queries
# and `nsd` bound to the public ethernet interface for remote DNS queries asking
# about our domain names. `nsd` is configured later.
#
# About the settings:
#
# * RESOLVCONF=yes will have `bind9` take over /etc/resolv.conf to tell
#   local services that DNS queries are handled on localhost.
# * Adding -4 to OPTIONS will have `bind9` not listen on IPv6 addresses
#   so that we're sure there's no conflict with nsd, our public domain
#   name server, on IPV6.
# * The listen-on directive in named.conf.options restricts `bind9` to
#   binding to the loopback interface instead of all interfaces.
apt_install bind9 resolvconf
tools/editconf.py /etc/default/bind9 \
    RESOLVCONF=yes \
    "OPTIONS=\"-u bind -4\""
if ! grep -q "listen-on " /etc/bind/named.conf.options; then
    # Add a listen-on directive if it doesn't exist inside the options block.
    sed -i "s/^}/\n\tlisten-on { 127.0.0.1; };\n\tmax-recursion-queries 200;\n}/" /etc/bind/named.conf.options
    sed -i "s/listen-on-v6 { \(any;\) };/listen-on-v6 { ::1; };/" /etc/bind/named.conf.options
fi
if [ -f /etc/resolvconf/resolv.conf.d/original ]; then
    echo "Archiving old resolv.conf (was /etc/resolvconf/resolv.conf.d/original, now /etc/resolvconf/resolv.conf.original)"
    mv /etc/resolvconf/resolv.conf.d/original /etc/resolvconf/resolv.conf.original
fi

# update root servers
hide_output wget -O /etc/bind/db.root "http://www.internic.net/domain/named.root"

# Restart the DNS services.

restart_service bind9
restart_service resolvconf

# ### Fail2Ban Service

# Configure the Fail2Ban installation to prevent dumb bruce-force attacks against dovecot, postfix and ssh
cp conf/fail2ban/jail.local /etc/fail2ban/jail.local

restart_service fail2ban
