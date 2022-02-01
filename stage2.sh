
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
