FILE=~/tdx-guest.qcow2

/usr/bin/qemu-system-x86_64 \
        -accel kvm \
        -object tdx-guest,sept-ve-disable=on,id=tdx0 \
        -object memory-backend-memfd-private,id=ram1,size=4G \
        -machine q35,kernel_irqchip=split,confidential-guest-support=tdx0,memory-backend=ram1 \
        -cpu host,pmu=off,-kvm-steal-time \
        -smp 4 \
        -drive file=${FILE},if=virtio \
        -netdev user,id=net0 \
        -device virtio-net,netdev=net0 \
        -vga none \
        -serial stdio \
        -bios /usr/share/qemu/tdvf-x86_64.bin
