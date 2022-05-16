# hello-qemu
Project for Canonical take home test

The object is to create a Linux image that runs under qemu that prints "hello world" during the boot process.

I am going to take the current running ISO image of Tiny Core Linux and alter the booting root image to include a new startup script.

The script willl download the current TC image if it's not available and create an unaltered qemu boot image from it.

Then it will create a duplicate of this image, and alter the initrd image with the new boot script.

To complete this problem, run the script qemu-hello-world.sh in the project directory.

To shut down any qemu instance running these images, once the system has finished booting and reaching the command prompt, run:

```
sudo poweroff
```

To clean up the build products, run the cleanup.sh script. It will, however, leave the Core-current.iso file in place to save download bandwidth.

