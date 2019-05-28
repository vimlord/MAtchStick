# MAtchStick

MatchStick is a customizable Arch Linux installer that formats a USB
with a bootable exam environment. The tool installs the operating system
with a custom authentication module (Pluggable Authentication Module; PAM)
and provides key management to ensure that the users can only login once.
The system is also designed to ensure that users cannot access the internet.
There is also a provisioning script that synchronizes the keys with a
proctor's machine and provides the necessary keys for a one-time password.

The script was originally developed between January and May of 2019 for the
purpose of use in exams. We wanted to create the device so that students could
have access to a compiler and text editor in a exam environment without access
to the internet. While the prototype was never used in a classroom setting,
we decided to open source it in the hopes that it could potentially be used
in the future.

# Setup

To use the installation script, you will need to run it from Arch Linux,
as it makes use of the arch installation scripts. These are available in
the [arch-install-scripts](https://www.archlinux.org/packages/?name=arch-install-scripts)
package, and can thus be installed with `pacman -S arch-install-scripts`.

The script consists of several parts: a component that prepares for installation
on the disk, and a component that performs the installation through chroot.
The preinstallation handles:

* Formatting and partitioning of the USB device
* File system table (fstab) initialization
* Copying installation files to the USB for installation

The device installation handles:

* Locale and hostname setup (the default is 'exam')
* User creation and configuration (the student user is 'student')
* Authentication setup
    * Student keygen
    * PAM installation
* Bootloader installation
* Package installation
* Environment configuration

## Customization

The script is customizable in several ways. First, the main script allows
for a specific password to be used for the disk encryption. The default is
'password', but can be changed by modifying the `CRPYTROOT_PASSWD` variable.

The packages provided are also customizable in the `chroot_installer.sh` file.
The current configuration will provide Java 8 (jre, jdk, doc), Python 3, Vim,
Emacs, and the `midori` web browser for browsing local HTML files. There are
also configurations provided to install Emacs in both scripts.

# Usage

To create the USB, you must know what device the USB is, and you must specify
a mount point. For example, the device may be `/dev/sdb`. On Linux, a mount
point such as `/mnt` is typically provided. So, one can install the USB from
a sufficient Arch Linux device by running

`sudo sh install.sh /dev/sdb /mnt`

Note that sudo is used. Since disk partitioning and mounting operations are
utilized, root privileges are required. With this, it is absolutely necessary
that extreme caution be used when running the script. The program will wipe
whatever device is in use without any regard, and mistyping the device
name or other components will almost certainly lead to irreversible damage
to your operating system. Always make certain what is being run on your system
before running it. The script is not designed to have any effect on your
system, but will modify the contents of the USB. On such devices, be aware of
any write limitations, notably the maximum available number of writes.

Once the USB is created, it can be booted through your computer's boot menu.
The USB requires UEFI compatibility to be booted, which will only be an issue
with older computers. However, this is anticipated to be unlikely to cause
issues.

# Credits

This script was developed by Christopher Hittner and Justin Barish.

Copyright 2019 Christopher Hittner and Justin Barish. All Rights Reserved.

