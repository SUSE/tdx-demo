#! /bin/bash
# author: Claudio Fontana <cfontana@suse.de>

REPO=tdx-demo-packages

# check if $REPO repo already exists, if not add it.

if zypper lr 2>/dev/null | grep -q $REPO ; then
    echo "$0: *************************************************"
    echo "$0: SUCCESS: DEMO $REPO repository exists"
else
    if zypper ar -e -f https://download.opensuse.org/repositories/devel:/coco:/Leap15.5/15.5/ $REPO ; then
	echo "$0: ***************************************************"
	echo "$0: SUCCESS: DEMO $REPO repository is added"
    else
	ZC=$?
	echo "$0: ******************************************************************************"
	echo "$0: FAILURE: DEMO $REPO repository could not be added, zypper code $ZC"
	exit 1
    fi
fi

# refresh repos and import keys

if zypper -q --gpg-auto-import-keys refresh ; then
    echo "$0: *******************************"
    echo "$0: SUCCESS: repositories refreshed"
else
    echo "$0: ********************************"
    echo "$0: FAILURE: could not refresh repos"
    exit 2
fi

# install packages

if zypper -q install -y --allow-vendor-change kernel-default qemu qemu-ovmf-tdx-x86_64 ; then
    echo "$0: ****************************************"
    echo "$0: SUCCESS: all DEMO $REPO installed"
else
    echo "$0: ***************************************"
    echo "$0: FAILURE: could not install $REPO"
    exit 3
fi


