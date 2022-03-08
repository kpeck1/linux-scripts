#!/usr/bin/env sh
# Uncomment for debugging
#set -x

###
# Just a dinky script to install the basics for different OSes
#
# Checked/Verified OSes:
#
# Alpine Linux 3.x
# Amazon Linux AMI 1/2
# Arch Linux
# CentOS 7/8/9
# Debian 8 (Jessie)/9 (Wheezy)/10 (Buster)/11 (Bullseye)
# Fedora 20/21/22/23/24/25/26/27/28/29/30/31/32/33/34/35/36/Rawhide
# Gentoo Linux
# OpenSuSE Leap 13.[0-2]/42/15.[0-3]/Tumbleweed
# Oracle Linux 7/8
# SLE 12 SP[4,5]/15 SP[0-3]
# RHEL 7/8/9
# Ubuntu 14.04 (Trusty)/16.04 (Xenial)/18.04 (Bionic)/20.04 (Focal)/21.04 (Hirsute)/21.10 (Impish)/22.04 (Jammy)
#
# v1.0/2021-11-30/PotatoSkin15/Initial script
# v1.1/2021-12-01/PotatoSkin15/Added more Fedora support and started testing
# v1.1.1/2021-12-06/PotatoSkin15/Added support for CentOS 9 Stream
# v1.2/2021-12-06/PotatoSkin15/Added support for Arch Linux
# v1.3/2021-12-08/PotatoSkin15/Added support for Alpine Linux and changed bash to sh
###

###
# Functions
###

# Define help message
helpMsg() {
	printf '\n%s\n' "Usage: $0 [-v] [-h]"
	printf '%s\n' "-v: Enable verbose mode"
	printf '%s\n\n' "-h: Print this help message"
}

# For when verbose is specified
log() {
	if "$verbose"; then
		echo "$@"
		"$@"
	fi
}

# Fix for selinux
selinuxFix() {
	selinuxCheck=$(rpm -qa selinux-policy)
	if [ -n "$selinuxCheck" ]; then
		setenforce 0
		sed -i -e 's/^SELINUX=.*/SELINUX=permissive/g' /etc/selinux/config
	fi
}

###
# Argument Parsing
###

# Run through any options with getopts
while getopts "v:h:" flag; do
	case "${flag}" in
		v) verbose=true;;
		h) helpMsg "$@" && exit 1;;
		*) helpMsg "$@" && exit 1;;
	esac
done

###
# Variable Declaration
###

# Get OS
OS=$(grep -E ^ID= /etc/os-release | awk -F '"' '{ print $2 }')

# Do a quick test on OS variable
# Fedora/Debian/Ubuntu don't have double-quotes
if [ -z "$OS" ]; then
	OS=$(grep -E ^ID= /etc/os-release | awk -F '=' '{ print $2 }')
fi

# Get OS Version
VER=$(grep -E ^VERSION_ID= /etc/os-release | awk -F '"' '{ print $2 }')

# Do a quick test on VER variable
# Fedora/Debian/Ubuntu don't have double-quotes
if [ -z "$VER" ]; then
	VER=$(grep -E ^VERSION_ID= /etc/os-release | awk -F '=' '{ print $2 }')
fi

# Create the systemOS version so we can case it
systemOS="$OS:$VER"

# Set the USER variable
# If run inside containers, this is unfortunately needed
USER=$(whoami)

###
# Main Script
###

# If verbose was passed in, set verbose
# Commenting this out as it needs to be fixed
#if "$verbose"; then
#	log "$@"
#fi

# Check if user is root, if not they should run as root
if [ "$USER" != "root" ]; then
	printf '\n%s\n' "WARNING! This script should be run as root"
	printf '%s\n\n' "Please enter sudo su and run the script again"
	exit 1
fi

# Spit out the OS
printf '\n%s\n' "$systemOS Detected"

case "$systemOS" in
	centos:7|redhat:7|"amzn:2"*|"ol:7."*|"fedora:2"[0,1])
		# Update everything currently installed
		# Install deltarpm from the start to make it go faster
		yum makecache fast
		yum -y install deltarpm
		yum -y update

		# We'll key off the output of rpm -qa selinux-policy to determine if SELinux is installed
		# If installed, we'll temporarily turn off SELinux and put SELinux into permissive mode
		# If not, we'll move on
		selinuxFix "$@"

		# Install EPEL and SCL repos and update
		# Oracle Linux calls it "oracle-epel-release-el7", but it's still EPEL
		# If the OS variable matches any condition, do it the OS-specific way
		# If not, just install EPEL
		case "$systemOS" in
			"ol:7"*) yum -y install oracle-epel-release-el7 scl-utils scl-utils-build;;
			amzn:2) amazon-linux-extras install epel -y && yum -y install scl-utils scl-utils-build;;
			redhat:7) yum -y install epel-release && yum-config-manager --enable rhel-server-rhscl-7-rpms;;
			centos:7) yum -y install epel-release centos-release-scl;;
			*) yum -y install epel-release
		esac
		yum makecache fast

		# Install some basics that should get us going
		yum -y install git vim htop wget openssh openssh-server net-tools kernel-devel firewalld zip bzip2 curl rpm-build epel-rpm-macros

		# Install the Development Tools meta/group package
		yum -y groupinstall 'Development Tools'
	;;
	"centos:"[8,9]|"redhat:"[8,9]|"fedora:"*|"ol:8."*)
		# Update everything currently installed
		# Install drpm (deltarpm) from the start to make it go faster
		dnf check-update
		dnf -y install drpm

		# Check if we have a Fedora distribution older than Fedora 22
		# If so, we'll install some tools to use and then dnf update
		# If not, just run dnf update
		if expr "$VER" : "2[2-5]" > /dev/null; then
			dnf -y install python-dnf-plugins-extras-migrate
			dnf-2 -y migrate
			dnf -y update
		else
			dnf -y update
		fi

		# We'll key off the output of rpm -qa selinux-policy to determine if SELinux is installed
		# If installed, we'll temporarily turn off SELinux and put SELinux into permissive mode
		# If not, we'll move on
		selinuxFix "$@"

		# Install epel-release and update
		# Oracle Linux calls it "oracle-epel-release-el8", but it's still EPEL
		if [ "$OS" = "ol" ]; then
			dnf -y install oracle-epel-release-el8
		elif [ "$OS" != "fedora" ]; then
			dnf -y install epel-release
		fi
		dnf check-update

		# Install some basics that should get us going
		dnf -y install git vim htop wget openssh openssh-server net-tools kernel-devel firewalld zip bzip2 curl rpm-build epel-rpm-macros

		# Install the Development Tools meta/group package
		dnf -y group install "Development Tools"
		if [ "$OS" = "fedora" ]; then
			# With Fedora, we also need to install this extra group
			dnf -y group install "C Development Tools and Libraries"
		fi
	;;
	"opensuse"*|"sle"*)
		# Update everything currently installed
		# Install deltarpm from the start to make it go faster
		zypper -n ref
		zypper -n in deltarpm
		zypper -n up

		# Install some basics that should get us going
		zypper -n in git vim htop wget openssh openssh-server net-tools kernel-devel zip bzip2 curl rpm-build

		# Install devel_basis meta/group package
		zypper -n in -t pattern devel_basis
	;;
	"ubuntu:"*|"debian:"*)
		# Set the DEBIAN_FRONTEND to noninteractive so that it doesn't try to reconfigure any packages as we do this
		export DEBIAN_FRONTEND=noninteractive

		# Update everything currently installed
		apt-get update
		apt-get -y upgrade
		apt-get -y dist-upgrade
		apt-get -y autoclean
		apt-get -y autoremove

		# Install some basics that should get us going
		apt-get -y install git vim htop wget openssh-server net-tools

		# Install build-essential meta/group package
		apt-get -y install build-essential
	;;
	"arch:"*)
		# Update everything currently installed
		pacman -Sc --noconfirm
		pacman -Syy
		pacman -Syu --noconfirm

		# Install some basics that should get us going
		pacman -S --noconfirm git vim htop wget openssh net-tools linux-headers zip bzip2 curl

		# Install base-devel group package and base metapackage
		pacman -S --noconfirm base
		pacman -S --noconfirm base-devel
	;;
	"gentoo:"*)
		# Update everything currently installed
		emerge --sync
		emerge --update --deep --changed-use @world
		emerge --depclean

		# Install some basics that should get us going
		emerge eix git vim htop wget openssh openssh-server net-tools linux-headers zip bzip2 curl
		eix-update
	;;
	"alpine:3."*)
		# Update everything currently installed
		apk update
		apk upgrade

		# Install some basics that should get us going
		apk add git vim htop wget openssh openssh-server net-tools zip bzip2 curl bash

		# Install alpine-sdk and build-base
		apk add alpine-sdk build-base
	;;
	*)
		printf '\n%s\n' "ERROR! Supported OS not detected! Exiting!"
		exit 1
	;;
esac