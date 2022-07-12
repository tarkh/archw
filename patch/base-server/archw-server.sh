ARCHW SERVER SETUP
==================
mkdir Minecraft_Server
tar -xf Minecraft_Server.xva -C Minecraft_Server
xva-img -p disk-export Minecraft_Server/Ref\:28/ Minecraft_Server.raw
qemu-img convert -p -f raw Minecraft_Server.raw -O qcow2 Minecraft_Server.qcow2
==================

pacstrap /mnt base linux-lts linux-firmware intel-ucode \
base-devel parted grub openssh curl wget ntp zip unzip nano vim git networkmanager \
efibootmgr dosfstools os-prober mtools \
acpi cpupower lm_sensors btop sysbench

#
# Install VM Host tools
pacman -S dmidecode qemu-base libvirt iptables-nft dnsmasq bridge-utils openbsd-netcat vde2 virt-viewer virt-install libguestfs cockpit cockpit-machines cockpit-pcp udisks2 packagekit

systemctl enable libvirtd
systemctl enable udisks2
systemctl enable pmlogger

#
# Converter tools (XVA > qcow2)
pacman -S xxhash cmake
git clone https://github.com/eriklax/xva-img.git
cd xva-img/
cmake .
sudo make install
cd ../

#
# Additional guest disk tools
#yay -S guestfs-tools

#
# Kernrl modules
bash -c "cat >> /etc/modprobe.d/kvm_intel.conf" << EOL
options kvm_intel nested=1
EOL

bash -c "cat >> /etc/modules-load.d/virtio-net.conf" << EOL
virtio_net
EOL

bash -c "cat >> /etc/modules-load.d/mdev.conf" << EOL
mdev
EOL
