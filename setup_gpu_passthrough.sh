#!/bin/bash
cat << EOF
Please enter a number to choose an option:
1. Check if VT-x/AMD-V and IOMMU are enabled
2. Enable GPU passthrough
3. Verify GPU passthrough
4. Revert changes
EOF

read -p "Option: " option

if [ $option -eq 1 ]; then
    virt_type=$(lscpu | grep -i virtualization)
    if [[ $virt_type == *'VT-x'* || $virt_type == *'AMD-V'* ]]; then
        echo "Virtualization is enabled."
    else
        echo "CPU virtualization is current not enabled. Please check BIOS settings to see if the feature is enabled."
    fi
    
    if dmesg | grep -q "AMD-Vi: Interrupt remapping enabled" || dmesg | grep -q "DMAR-IR: Enabled IRQ remapping in x2apic mode"; then
        echo "IOMMU remapping is enabled."
    else
        echo "IOMMU remapping is current not enabled. Please check BIOS settings to see if the feature is enabled."
    fi

elif [ $option -eq 2 ]; then
    if lscpu | grep -q Intel; then
        sed -i 's/quiet/quiet intel_iommu=on iommu=pt/' /etc/default/grub
    elif lscpu | grep -q AMD; then
        sed -i 's/quiet/quiet iommu=pt/' /etc/default/grub
    fi

    /usr/sbin/update-grub

    echo vfio >> /etc/modules
    echo vfio_iommu_type1 >> /etc/modules
    echo vfio_pci >> /etc/modules

    device_id=$(lspci -nn | grep -Ei "vga|3d" | grep -i nvidia | sed -n 's/.*\[\([0-9a-fA-F:]*\)\].*/\1/p')
    if [ "$device_id" ]; then
        echo "options vfio-pci ids=$device_id" >> /etc/modprobe.d/vfio.conf
        echo "softdep nouveau pre: vfio-pci" >> /etc/modprobe.d/vfio.conf
        echo "softdep nvidia pre: vfio-pci" >> /etc/modprobe.d/vfio.conf
        echo "softdep nvidiafb pre: vfio-pci" >> /etc/modprobe.d/vfio.conf
        echo "softdep nvidia_drm pre: vfio-pci" >> /etc/modprobe.d/vfio.conf
        echo "softdep drm pre: vfio-pci" >> /etc/modprobe.d/vfio.conf
    fi

    /usr/sbin/update-initramfs -u

    echo Please reboot for GPU passthrough to take effect.
    
elif [ $option -eq 3 ]; then
    if lspci -nnk | grep -A1 NVIDIA | grep -q vfio-pci; then
        echo GPU passthrough successfully enabled!
    else
        echo ERROR: vfio driver is not bound to the GPU device
    fi
    
elif [ $option -eq 4 ]; then
    sed -i 's/ iommu=pt//' /etc/default/grub
    sed -i 's/ intel_iommu=on//' /etc/default/grub

    /usr/sbin/update-grub

    sed -i '/vfio/d' /etc/modules
    sed -i '/vfio_iommu_type1/d' /etc/modules
    sed -i '/vfio_pci/d' /etc/modules

    device_id=$(lspci -nn | grep NVIDIA | cut -f10 -d' ' | tr -d [ | tr -d ])
    if [ "$device_id" ]; then
        sed -i "/options vfio-pci ids=$device_id/d" /etc/modprobe.d/vfio.conf
        sed -i '/softdep nouveau pre: vfio-pci/d' /etc/modprobe.d/vfio.conf
        sed -i '/softdep nvidia pre: vfio-pci/d' /etc/modprobe.d/vfio.conf
        sed -i '/softdep nvidiafb pre: vfio-pci/d' /etc/modprobe.d/vfio.conf
        sed -i '/softdep nvidia_drm pre: vfio-pci/d' /etc/modprobe.d/vfio.conf
        sed -i '/softdep drm pre: vfio-pci/d' /etc/modprobe.d/vfio.conf
    fi

    /usr/sbin/update-initramfs -u
fi
