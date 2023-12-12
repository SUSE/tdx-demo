#! /bin/bash
# author: Claudio Fontana <cfontana@suse.de>
# assumes coreutils are installed

PROGRAM_NAME=$0
REPO=tdx-demo-packages
#REPO_LEN=${#REPO}
GUEST_DOWNLOAD=http://download.opensuse.org/distribution/leap/15.6/iso/
GUEST_ISO=openSUSE-Leap-15.6-DVD-x86_64-Build565.1-Media.iso
NEED_DOWNLOAD=y

# print separator line with asterisks
function print_sep () {
    printf '*%.0s' {1..60}
    printf "\n${PROGRAM_NAME}: "
    echo $*
}

function verify_sha () {
    if wget -O ${HOME}/tdx-guest.iso.sha256 ${GUEST_DOWNLOAD}/${GUEST_ISO}.sha256 ; then
	print_sep "SUCCESS: DEMO guest SHA downloaded to $HOME"
    else
	print_sep "FAILURE: could not download guest SHA to $HOME"
	exit 5
    fi
    print_sep "VERIFYING ISO SHA256..."
    SHA1=`cat ${HOME}/tdx-guest.iso.sha256`
    SHA2=`sha256sum ${HOME}/tdx-guest.iso`
    SHA1="${SHA1% *}"
    SHA2="${SHA2% *}"
    if test $SHA1 = $SHA2 ; then
	print_sep "SUCCESS: SHA256 OK"
	NEED_DOWNLOAD=n
    else
	print_sep "FAILURE: need to download"
	NEED_DOWNLOAD=y
    fi
}

# install needed utility packages
if zypper -q install -y wget ; then
    print_sep "SUCCESS: installed utility packages"
else
    print_sep "FAILURE: could not install utility packages"
    exit 1
fi

# check if $REPO repo already exists, if not add it.

if zypper lr 2>/dev/null | grep -q $REPO ; then
    print_sep "SUCCESS: DEMO $REPO repository exists"
else
    if zypper ar -e -f https://download.opensuse.org/repositories/devel:/coco:/Leap15.5/15.5/ $REPO ; then
	print_sep "SUCCESS: DEMO $REPO repository is added"
    else
	ZC=$?
	print_sep "FAILURE: DEMO $REPO repository could not be added, zypper code $ZC"
	exit 2
    fi
fi

# refresh repos and import keys

if zypper -q --gpg-auto-import-keys refresh ; then
    print_sep "SUCCESS: repositories refreshed"
else
    print_sep "FAILURE: could not refresh repos"
    exit 3
fi

# install packages

if zypper -q install -y --allow-vendor-change kernel-default qemu qemu-ovmf-tdx-x86_64 ; then
    print_sep "SUCCESS: all DEMO packages in $REPO installed"
else
    print_sep "FAILURE: could not install $REPO"
    exit 4
fi

# if the tdx guest ISO exists, verify SHA
if test -f ${HOME}/tdx-guest.iso ; then
    verify_sha
fi

# download DEMO guest ISO
if test "y" = "$NEED_DOWNLOAD" ; then
    if wget -O ${HOME}/tdx-guest.iso ${GUEST_DOWNLOAD}/${GUEST_ISO} ; then
	print_sep "SUCCESS: guest ISO downloaded to $HOME"
    else
	print_sep "FAILURE: could not download guest ISO to $HOME"
	exit 6
    fi
    # check SHA (again potentially)
    verify_sha
    if test "y" = "$NEED_DOWNLOAD" ; then
	print_sep "FAILURE: downloaded ISO failed SHA verification"
	exit 7
    fi
fi

# create DEMO guest image QCOW

if qemu-img create -f qcow2 ${HOME}/tdx-guest.qcow2 64G ;then
    print_sep "SUCCESS: guest QCOW2 created in $HOME"
else
    print_sep "FAILURE: could not create QCOW2 in $HOME"
    exit 7
fi

# install the DEMO guest: this requires some user interaction

/usr/bin/qemu-system-x86_64 \
    -accel kvm \
    -machine q35 \
    -cpu host,pmu=off,-kvm-steal-time \
    -smp 4 \
    -m 4G \
    -drive file=${HOME}/tdx-guest.qcow2,if=virtio \
    -netdev user,id=net0 \
    -device virtio-net,netdev=net0 \
    -serial stdio \
    -bios /usr/share/qemu/tdvf-x86_64.bin \
    -cdrom ${HOME}/tdx-guest.iso
