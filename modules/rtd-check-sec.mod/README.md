# RTD Checksec

[Back to Tool Reference](../../docs/TOOLS.md) | [Back to Modules](../README.md)

## Purpose

`rtd-check-sec` inspects Linux executables, processes, libraries, and kernel configuration for common exploit-mitigation indicators such as RELRO, stack canaries, NX, PIE, ASLR, and FORTIFY support. It packages the attributed `checksec.sh` utility as an RTD command.

## Good For

- Checking a compiled binary before deployment.
- Reviewing baseline mitigation settings on a Linux host.
- Comparing hardening indicators between application builds.

## Quick Start

```bash
rtd-check-sec --file /usr/bin/ssh
rtd-check-sec --dir /usr/bin
rtd-check-sec --kernel
```

## Options

```text
--file <executable-file>
--dir <directory> [-v]
--proc <process-name>
--proc-all
--proc-libs <process-id>
--kernel
--fortify-file <executable-file>
--fortify-proc <process-id>
--version
--help
```

## What It Changes

This command reports mitigation information; it does not harden or alter the inspected files or host configuration.

## Related Tools

- [`rtd-security-tool`](../Security-tool.mod/README.md) presents security configuration and scanning actions.
- [`rtd-malware-scan`](../oem-system-admin.mod/README.md) runs malware scans through the system-admin helpers.
