#!/bin/sh

name="speedie's gentoo-install script"
vers="v0.1"
user="$(whoami)"
stage3rc="https://mirror.bytemark.co.uk/gentoo//releases/amd64/autobuilds/current-stage3-amd64-systemd/stage3-amd64-openrc-20220130T170547Z.tar.xz"
stage3d="https://bouncer.gentoo.org/fetch/root/all/releases/amd64/autobuilds/20220130T170547Z/stage3-amd64-systemd-20220130T170547Z.tar.xz"
rice="https://github.com/speediegamer/configurations/archive/refs/heads/main.zip"
kernelconfig="https://raw.githubusercontent.com/speediegamer/configurations/main/usr/src/linux/.config"
clear

echo "$(hostname)"
echo " ____  ____  ____  "
echo "/ ___||  _ \|  _ \ "
echo "\___ \| |_) | | | |"
echo " ___) |  __/| |_| |"
echo "|____/|_|   |____/ "
echo "Welcome to $name"
echo "$vers"
echo "NOTE: Only supports AMD64 currently!!"
echo "Before we can start the installation, I will ask you a few questions"
echo  

if [ $user = "root" ]; then
	echo "You're running this script as root, good job!"
else
	echo "You're not running as root, please run this script with root permissions." && sleep 2 && exit
fi

echo
echo "--/Settings!\--"
echo

echo -n "Are we installing as EFI? Y/N: " && read EFI && echo "Alright, we're installing grub for EFI"
lsblk

if [ $EFI = "Y" ]; then
    echo -n "Enter the drive you wanna install Grub to: Example: /dev/sda1: " && read grubPartitionEFI && echo "$grubPartitionEFI will be your /boot partitiion"
else
	echo "Installing as MBR, will not ask for EFI partition"
fi

echo -n "Enter the drive you wanna install your Gentoo to: Example: /dev/sda2: " && read rootPartition && echo "$rootPartition will be your / partition"

if [ $EFI = "N" ]; then
	echo -n "Enter the full drive you wanna install Grub to: Example: /dev/sda: " && read grubPartitionEFI && echo "Using $grubPartitionEFI"
else
	echo "Ignoring MBR option!"
fi

echo -n "Would you like OpenRC or systemdick? openrc/systemd: " && read init && echo "Using $init"

echo -n "Do you wish to install my rice as well? Y/N: " && read rice && echo "Alright."

if [ $rice = "Y" ]; then
	echo -n "What Window Manager would you like to install? (Available: dwm): " && read wm && echo "$wm will be installed!"
else
	echo "Won't install Window Manager, you will have to do that yourself."
fi

if [ $rice = "Y" ]; then
	echo -n "What terminal would you like to install? (Available: st, urxvt): " && read term && echo "$term will be installed!"
else
	echo "Won't install Terminal, you will have to do that yourself."
fi

if [ $rice = "Y" ]; then
	echo -n "What shell would you like to install? (Available: Bash, Zsh): " && read shell && echo "$shell will be installed!"
else
	echo "No shell will be installed"
fi

if [ $rice = "Y" ]; then
	echo -n "Would you like to install doas? Y/N: " && read doas && echo "Alright."
else
	echo "Doas will not be installed!"
fi

echo -n "Would you like to use a distro kernel? If no, you will be asked to specify a URL to a kernel config. Y/N: " && read kernel && echo "Alright."

echo "If you're not sure, read https://wiki.gentoo.org/wiki/GCC_optimization or if you're compiling on the same machine you're installing, type native"

echo -n "What should we compile this for? Example: skylake: " && read arch && echo "Compiling for $arch"

echo -n "What MAKEOPTS should we use? This should be the lowest number of: How much ram you have divided by 2 or how many threads you have! Example: 8" && read compiler && echo "Using -j$compiler"

echo "-O2 is recommended, I personally use -O3 but it can cause code to break."
echo -n "What compile optimizations should we use? Examples: O0, O2, O3, Ofast: " && read OX && echo "Using -$OX"

echo -n "What timezone do we use? Examples: Europe/Amsterdam: " && read timezone && echo "Using $timezone"

echo -n "What locale would you like to use? Examples: en_US: " && read locale && echo "Using $locale"

echo -n "Would you like to specify a custom tarball? Y/N: " && read customtarball && echo "Ok."

if [ $customtarball = "Y" ]; then
	echo -n "Give me a link to a valid tarball: " && read stage3custom && echo "Ok"
else
	echo "No tarball needs to be provided." && stage3=N
fi

if [ "$stage3tarball" = "Y" ]; then
	echo -n "Is this a stage3 systemdick tarball or an OpenRC tarball?: systemd/openrc: " && read stage3init && echo "OK"
else
	echo "No custom tarball, ignoring.."
fi

if [ "$stage3init" = "systemd" ]; then
	stage3d="$(stage3init)"
elif [ "$stage3init" = "openrc" ]; then
	stage3rc="$(stage3init)"
fi

if [ $kernel = "N" ]; then
	echo -n "Specify a URL to a custom kernel. Or type speedie to use speedie's kernel: " && read kernelconfig
else
	echo "Ok." && kernelconfig=N
fi

if [ "$kernelconfig" = "speedie" ]; then
	kernelconfig="https://raw.githubusercontent.com/speediegamer/configurations/main/usr/src/linux/.config"
fi

echo -n "Would you like to have an initramfs? WARNING: Initramfs MUST use LZ4 compression and must be enabled in your kernel configuration! Y/N: " && read initramfs && echo "Alright."

echo "DO NOT SPECIFY SYSTEMD AS A USE FLAG, THIS WILL BE DONE AUTOMATICALLY!!"
echo "Examples of USE flags you can use: -wayland -gnome -kde -gtk -qt5"
echo -n "Specify some custom global USE flags, If you don't wanna specify any, Leave blank!: " && read useflags && echo "Alright"

echo "=============================================================="
echo "                           WARNING                            "
if [ EFI = "Y" ]; then
	echo "Warning: The contents of $rootPartition and $grubPartitionEFI will be deleted!"
else
	echo "Warning: The contents of $rootPartition will be deleted!"
fi

echo -n "Are you sure you wanna do this? Y/N: " && read confirm

if [ $confirm = "Y" ]; then
	echo "Alright, starting Gentoo installation process"
else
	echo "Quitting!" && sleep 3 && exit
fi

clear

if [ EFI = "Y" ]; then
	mkfs.vfat -F 32 $grubPartitionEFI && mkfs.ext4 $rootPartition
else
	mkfs.ext4 $rootPartition
fi

if [ EFI = "Y" ]; then
	mkdir -pv /mnt/gentoo/boot && mount $rootPartition /mnt/gentoo && mount $grubPartitionEFI /mnt/gentoo/boot && mounted=true
else
	mkdir -pv /mnt/gentoo && mount $rootPartition /mnt/gentoo && mounted=true
fi

if [ "$mounted" = "true" ]; then
	echo "We're successfully mounted :D"
else
	echo "Your partitions failed to mount. Please run the script again and make sure your inputs are valid! Are you sure you didn't forget to partition your disks?" && sleep 3 && exit
fi

cd /mnt/gentoo && ntpd -q -g && echo "Sync time using network."

if [ "$init" = "openrc" ]; then
        wget $stage3rc && echo "Downloaded stage3 to $rootPartition"
else
        wget $stage3d && echo "Downloaded stage3 to $rootPartition"
fi

tar xpvf stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner && echo "Unpacked the tarball to $rootPartition"

sed '/COMMON_FLAGS/d' /mnt/gentoo/etc/portage/make.conf
sed '/MAKEOPTS/d' /mnt/gentoo/etc/portage/make.conf

echo "COMMON_FLAGS='-$OX -pipe -march=$arch -mtune=$arch'" >> /mnt/gentoo/etc/portage/make.conf
echo "MAKEOPTS='-j$compiler -l$compiler'" >> /mnt/gentoo/etc/portage/make.conf

mkdir --parents /mnt/gentoo/etc/portage/repos.conf
cp /mnt/gentoo/usr/share/portage/config/repos.conf /mnt/gentoo/etc/portage/repos.conf/gentoo.conf
cp --dereference /etc/resolv.conf /mnt/gentoo/etc/

mount --types proc /proc /mnt/gentoo/proc && mount --rbind /sys /mnt/gentoo/sys && mount --make-rslave /mnt/gentoo/sys && mount --rbind /dev /mnt/gentoo/dev && mount --make-rslave /mnt/gentoo/dev && mount --bind /run /mnt/gentoo/run && mount --make-slave /mnt/gentoo/run && echo "Mounted stuff"

test -L /dev/shm && rm /dev/shm && mkdir /dev/shm && mount --types tmpfs --options nosuid,nodev,noexec shm /dev/shm && chmod 1777 /dev/shm /run/shm && echo "Compatibility stuff."

chroot /mnt/gentoo /bin/bash && source /etc/profile && export PS1="CHROOT ${PS1}" && echo "Chrooted to $rootPartition, it is now /"

emerge-webrsync && emerge --sync --quiet && echo "Sync"

if [ "$init" = "systemd" ]; then
	eselect profile set 17
else
	eselect profile set 1
fi

emerge --quiet --update --deep --newuse @world && echo "Updated @world"

if [ "$init" = "openrc" ]; then
    echo "USE:'-systemd $useflags alsa" >> /etc/portage/make.conf
else
    echo "USE:'$useflags alsa" >> /etc/portage/make.conf
fi

echo $timezone > /etc/timezone && emerge --config sys-libs/timezone-data
echo "$locale ISO-8859-1" >> /etc/locale.gen
echo "$locale.UTF-8 UTF-8" >> /etc/locale.gen && locale-gen
echo "$locale.UTF-8" >> /etc/env.d/02locale

env-update && source /etc/profile

emerge sys-fs/genfstab && echo "Emerged genfstab"

if [ kernel = "Y" ]; then
	emerge sys-kernel/installkernel-gentoo && emerge sys-kernel/gentoo-kernel-bin && emerge linux-firmware && emerge --depclean
else
	emerge gentoo-sources && emerge app-arch/lz4 && emerge genkernel && emerge linux-firmware && eselect kernel set 1 && cd /usr/src/linux && make mrproper && rm -rf .config && wget $kernelconfig && make olddefconfig && make -j$compiler && make modules_prepare && make modules_install && make install && echo "Installed kernel"
fi

if [ initramfs = "Y" ]; then
	genkernel --help && genkernel --install --kernel-config=/usr/src/linux/.config initramfs
else
	echo "Will not use initramfs"
fi

genfstab -U / >> /etc/fstab && echo "Generated fstab in /etc/fstab"

echo "hostname='gentoo'" >> /etc/conf.d/hostname

emerge net-misc/dhcpcd && emerge --noreplace net-misc/netifrc && rc-update add dhcpcd default && rc-service dhcpcd start && echo "Emerged basic network tools (netifrc, dhcpcd) and enabled dhcpcd"

emerge sys-fs/e2fsprogs && echo "Emerged e2fsprogs (ext4)" && emerge sys-fs/dosfstools && echo "Emerged dosfstools (fat)"

if [ $EFI = "Y" ]; then
	echo 'GRUB_PLATFORMS="efi-64"' >> /etc/portage/make.conf
else
	echo "Using MBR, won't add GRUB_PLATFORMS to make.conf"
fi

emerge sys-boot/grub && echo "Emerged grub bootloader"

if [ $EFI = "Y" ]; then
	grub-install --target=x86_64-efi --efi-directory=/boot && grub-mkconfig -o /boot/grub/grub.cfg
else
	grub-install $grubPartitionEFI
fi





