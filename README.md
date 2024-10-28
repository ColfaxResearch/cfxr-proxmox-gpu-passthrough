# cfxr-proxmox-gpu-passthrough
The purpose of this project is to automate GPU passthrough for Proxmox based systems.
Proxmox is a Debian based hypervisor that can be managed via a web interface. It is installed similar to any other Linux distribution.
GPU passthrough gives direct control of a GPU or other PCI device via a VM.
More information can be found from the Colfax Research article: [GPU passthrough on Proxmox](https://research.colfax-intl.com/?p=14401)

The automation consists of the `setup_gpu_passthrough.sh` script.
When executed, the script will give four options which are described in further detail below:
1. Check if VT-x/AMD-V and IOMMU are enabled
2. Enable GPU passthrough
3. Verify GPU passthrough
4. Revert changes

## Check if VT-x/AMD-V and IOMMU are enabled
This option will check if the appropriate CPU virtualization and IOMMU features are enabled.

## Enable GPU passthrough
This option will make the necessary changes to allow Proxmox to passthrough a GPU device to a VM.
Once passthrough is enabled and assigned to a VM, the GPU device cannot be shared between the VM and host or other VMs.

## Verify GPU passthrough
This option will verify that the VFIO driver is properly bound to the GPU device. If it isn't, it will return an error message.
Note: this option assumes that you have added the GPU device to a VM. If you have not, then it may return an error.

## Revert changes
This option will revert any changes that script makes. It will not delete any files, it will simply revert the changes made by the automation.

### Disclaimer
Use at your own discretion. Tested on new installation of Promox VE 8.2.2.
