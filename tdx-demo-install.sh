#! /bin/bash
# author: Claudio Fontana <cfontana@suse.de>
# assumes coreutils are installed

PROGRAM_NAME=$0

# the repo with the experimental TDX demo packages, for 15.5 ONLY

REPO_URL=https://download.opensuse.org/repositories/devel:/coco:/Leap15.5/15.5/
REPO_NAME=tdx-demo-packages

GUEST_URL=https://download.opensuse.org/repositories/Virtualization:/Appliances:/Images:/openSUSE-Leap-15.6/images/
GUEST_QCOW2=openSUSE-Leap-15.6-Minimal-VM.x86_64-kvm-and-xen.qcow2

NEED_DOWNLOAD=y

# print separator line with asterisks
function print_sep () {
    printf '*%.0s' {1..60}
    printf "\n${PROGRAM_NAME}: "
    echo "$*"
}

function verify_sha () {
    if wget -O ${HOME}/tdx-guest.qcow2.sha256 ${GUEST_URL}/${GUEST_QCOW2}.sha256 ; then
	print_sep "SUCCESS: DEMO guest SHA downloaded to $HOME"
    else
	print_sep "FAILURE: could not download guest SHA to $HOME"
	exit 5
    fi
    print_sep "VERIFYING QCOW2 SHA256..."
    SHA1=`cat ${HOME}/tdx-guest.qcow2.sha256`
    SHA2=`sha256sum ${HOME}/tdx-guest.qcow2`
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

# check if $REPO_NAME repo already exists, if not add it.

if zypper lr 2>/dev/null | grep -q $REPO_NAME ; then
    print_sep "SUCCESS: DEMO $REPO repository exists"
else
    if zypper ar -p 1 -e -f ${REPO_URL} ${REPO_NAME} ; then
	print_sep "SUCCESS: DEMO $REPO_NAME repository is added"
    else
	ZC=$?
	print_sep "FAILURE: DEMO $REPO_NAME repository could not be added, zypper code $ZC"
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

print_sep "Installing packages, this might take a while, please be patient..."

if zypper -q install -y --allow-vendor-change kernel-default qemu qemu-ovmf-tdx-x86_64 qemu-tools ; then
    print_sep "SUCCESS: all DEMO packages in $REPO_NAME installed"
else
    print_sep "FAILURE: could not install $REPO_NAME"
    exit 4
fi

# if the tdx guest QCOW2 exists, verify SHA
if test -f ${HOME}/tdx-guest.qcow2 ; then
    verify_sha
fi

# download DEMO guest QCOW2
if test "y" = "$NEED_DOWNLOAD" ; then
    if wget -O ${HOME}/tdx-guest.qcow2 ${GUEST_URL}/${GUEST_QCOW2} ; then
	print_sep "SUCCESS: guest QCOW2 downloaded to $HOME"
    else
	print_sep "FAILURE: could not download guest QCOW2 to $HOME"
	exit 6
    fi
    # check SHA (again potentially)
    verify_sha
    if test "y" = "$NEED_DOWNLOAD" ; then
	print_sep "FAILURE: downloaded QCOW2 failed SHA verification"
	exit 7
    fi
fi

print_sep 'If you installed for the first time, please reboot into the updated TDX DEMO kernel.

Then run:

./tdx-demo-run.sh

to start the OpenSUSE Leap Alpha 15.6 TDX guest.'
