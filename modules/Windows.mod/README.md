# Scripts and Tools to be Used With Windows (VM)

Herin are a few scripts that may be injected in to a windows VM as desired. By default the _rtd.library will pull in any script placed in this directory beginning wiht an underrscor " _" and make it available to the Windows VM. Primarily this will be done via a virtual FHD device in QEMU(KVM).

## Overview

Scripts and components may be included like thus in an OEM script (bash and mtools):

```bash
mkfs.msdos -C ${WindowsInstructions} 1440 || rtd_oem_pause 1

for i in "${_OEM_DIR}/modules/Windows.mod/_*" ; do
	mcopy -i ${WindowsInstructions} ${i} ::/ || rtd_oem_pause 1
done
```

Then launch the KVM install as normal for a windows install:

```bash
"${BIN_VIRT_INSTALL}" --connect qemu:///system --name "VDI_Windows${target_winver:(-2)}_${CONFIG}_${RANDOM}" \
	--vcpus "${cpu_count}" \
	--memory "${mem_size}" \
	--network "${virt_net}" \
	--video ${preferred_video} \
	--disk size="${disk_size}" \
	--os-variant="${target_winver}" \
	--cdrom "${WindowsMedia}" \
	--disk "${WindowsInstructions}",device=floppy \
	--livecd \
        --tpm default \
       ${uefi_option}

```

If the file being included in a windows setup for a VM it may be kind to launch this for the user or deployment technician. To do this the script or executable must be referenced in the Autounattend.xml file used by Windows automatic installs.

Example Extract From Autounattend.xml:

```xml
<FirstLogonCommands>
<SynchronousCommand wcm:action="add">
        <CommandLine>powershell -Command "a:\_Chris-Titus-Post-Windows-Install-App.ps1"</CommandLine>
<Description>Run Software install</Description>
 <Order>1</Order>
</SynchronousCommand>
</FirstLogonCommands>
```
