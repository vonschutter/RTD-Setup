# Third-Party Notes

## macOS-Simple-KVM FetchMacOS Helper and Clover ESP

This module uses the `fetch-macos.py` helper from:

```text
https://github.com/foxlet/macOS-Simple-KVM
```

RTD downloads the helper and Clover ESP image at runtime from the upstream repository. These files are not vendored into this module, and generated Apple recovery media is not committed to Git.

Default runtime URL:

```text
https://raw.githubusercontent.com/foxlet/macOS-Simple-KVM/master/tools/FetchMacOS/fetch-macos.py
https://raw.githubusercontent.com/foxlet/macOS-Simple-KVM/master/ESP.qcow2
```

The helper project is distributed under its own upstream license. Review the upstream repository before redistributing or modifying any copied code.

## KVM-OpenCore Boot Image

On AMD hosts, RTD defaults to the KVM-OpenCore boot image from:

```text
https://github.com/thenickdude/KVM-Opencore
```

Default runtime URL:

```text
https://github.com/thenickdude/KVM-Opencore/releases/download/v21/OpenCore-v21.iso.gz
```

The upstream project notes that the release files are raw hard disk images even when their filenames use `.iso`. RTD decompresses the image into the libvirt boot cache and attaches it as a raw disk.
