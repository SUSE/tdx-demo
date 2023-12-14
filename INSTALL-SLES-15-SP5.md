# Setting up a DEMO TDX Host Hypervisor on SLES 15-SP5 and openSUSE Leap 15.5

This document describes how to set up a DEMO host hypervisor to run confidential
virtual machines protected by the Intel Trusted Domain Extensions (TDX). The
steps can be followed on openSUSE Leap 15.5 or SUSE Linux Enterprise Server 15-SP5.

Note that the TDX support packages going to be installed by following the
instructions below are provided for **DEMO** purposes only. There is no support
provided by SUSE for these packages or any setups derived from following this
document.

If you run into issues, please report them [here](https://github.com/SUSE/tdx-demo/issues).

## Preparing the Host Environment

First of all, make sure that your hardware is TDX-capable,
and that you are running on the host either SUSE Linux Enterprise 15 SP5, or openSUSE Leap 15.5.
This DEMO will likely not work on other host Operating Systems.

In order to use TDX a number of options need to be enabled in the systems firmware settings. Please refer to this 
[Intel document](https://github.com/intel/tdx-linux/wiki/Instruction-to-set-up-TDX-host-and-guest#setup-tdx-host-in-bios)
for details.

## Installing Host Hypervisor Components

Using TDX capabilities on Intel hardware requires support in the Linux kernel,
the QEMU virtual machine monitor and the guest virtual firmware. These changes
are not yet completely merged into their upstream code-streams, so the SUSE
default packages can not yet support Intel TDX.

SUSE packaged the non-upstream code that is available and provides updated
packages for users and customers to experiment with this new technology.

## Quickstart Scripts

To get things going quickly you can get the scripts
[tdx-demo-install.sh](tdx-demo-install.sh) and
[tdx-demo-run.sh](tdx-demo-run.sh).

The `tdx-demo-install.sh` script sets up the necessary repositories and
downloads the Demo guest image. A reboot of the host is required in order to
load the new TDX-enabled kernel in the host.

When the host is set up, `tdx-demo-run.sh` runs the Demo guest image with TDX
enabled. This is sufficient to install and run the DEMO, but read further for
more details if needed.

## Manual instructions

To install these packages manually, an additional repository needs to be added
via zypper. On openSUSE Leap 15.5 or SUSE Linux Enterprise Server this can be
done via

```
$ sudo zypper ar -p1 -e -f https://download.opensuse.org/repositories/devel:/coco:/Leap15.5/15.5/ tdx-demo-packages
$ sudo zypper refresh
```

Now the required packages can be installed. Note that the QEMU package will
replace the default version shipped by the distribution. To install all required
packages, do:

```
$ sudo zypper install --allow-vendor-change kernel-default qemu qemu-ovmf-tdx-x86_64 qemu-tools
```

This command will install a TDX capable kernel and QEMU together with the
firmware required to run a TDX enabled virtual machine.

After installation is finished, reboot the system into the new kernel.  When
the machine is up again you can check the kernel log if TDX was set up
successfully:

```
$ sudo dmesg | grep -i tdx
[...]
[   48.238203] tdx: TDX module initialized.
[   48.243492] kvm_intel: tdx: max servtds supported per user TD is 1
[   48.251313] kvm_intel: tdx: live migration supported
[   48.257755] kvm_intel: TDX is supported.
```

If the output looks similar to the messages above then your system is ready to
run TDX enabled virtual machines.

## Preparing the Guest Image

To prepare a guest image you just need to install a Linux distribution
into a disk image file and make sure that EFI and secure boot is enabled.
Currently we recommend to use openSUSE 15.6 as the guest operating system,
because it includes all the latest updates for optimal TDX guest support.

The easiest way to do that is to create an image file and launch QEMU without
enabling TDX. Make sure you have an installation ISO image available. The
ISO file can be downloaded from [this server](http://download.opensuse.org/distribution/leap/15.6/iso/).

```
images $ ls -l
-rw-r--r-- 1 joro joro   4335861760 Dec 12 08:59 openSUSE-Leap-15.6-DVD-x86_64-Current.iso
images $ qemu-img create -f qcow2 tdx-guest.qcow2 64G
```

That creates the disk image file in the same directory as the installation ISO
image. Then, in the same directory, do:

```
images $ /usr/bin/qemu-system-x86_64 \
	-accel kvm \
	-machine q35 \
	-cpu host,pmu=off,-kvm-steal-time \
	-smp 4 \
	-m 4G \
	-drive file=tdx-guest.qcow2,if=virtio \
	-netdev user,id=net0 \
	-device virtio-net,netdev=net0 \
	-serial stdio \
	-bios /usr/share/qemu/tdvf-x86_64.bin \
	-cdrom openSUSE-Leap-15.6-DVD-x86_64-Current.iso
```

During the installation process, make sure that Secure boot is enabled for the
image.

## Launching a TDX guest

Once the installation is done and you verified it reboots correctly, it is time
to enable TDX. Change the command line to:

```
images $ sudo /usr/bin/qemu-system-x86_64 \
	-accel kvm \
	-object tdx-guest,sept-ve-disable=on,id=tdx \
	-object memory-backend-memfd-private,id=ram1,size=4G \
	-machine q35,kernel_irqchip=split,confidential-guest-support=tdx,memory-backend=ram1 \
	-cpu host,pmu=off,-kvm-steal-time \
	-smp 4 \
	-drive file=tdx-guest.qcow2,if=virtio \
	-netdev user,id=net0 \
	-device virtio-net,netdev=net0 \
	-serial stdio \
	-bios /usr/share/qemu/tdvf-x86_64.bin
```

By using this command line QEMU will enable TDX protections for this virtual
machine. After it booted up you can check the kernel log for TDX being
enabled:

```
# dmesg | grep -i tdx
[...]
[    0.000000][    T0] tdx: Guest detected
[    0.402006][    T0] process: using TDX aware idle routine
[    0.402006][    T0] Memory Encryption Features active: Intel TDX
```

If you see messages like this in the kernel log, then TDX was successfully
enabled and your virtual machine is protected and set up for further
experimentation with this exciting new feature.

Have a lot of fun!
