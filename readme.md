# MAtchStick

MAtchStick is a customizable Arch Linux distribution that is designed to run
on a USB stick for exam conditions. MAtchStick is designed to be a locked-down
environment, where users do not have internet access, only have access to 
already installed programs and tools, and only can log in once. In order to
achieve a one time login, a customized protocol was created to allow a login
password to be set on the USB sticks every time they are used.

MAtchStick was originally developed between January and May of 2019 for the
purpose of use in exams to create a device so that students could
have access to a compiler and text editor in a exam environment, without access
to the internet. 

Usage of the MAtchStick requires having 3 computer roles - the computer burning
the customized Arch Linux distributions to the USB drives, the proctor's computer provisioning the 
USB drives with the password for the exam session and grabbing the completed
submissions afterwards, and the host computer running the Arch Linux on the USB drives.
Note that the first 2 roles can be combined on the same computer. 
This readme is broken down into 3 sections, outlining each of the mentioned roles.

The typical use case is as follows:
1. Burning computer creates USB drives, and students configure their BIOS to 
work with the drives
2. Provisioning computer sets the password for the USB drives
3. Student uses the USB drives
4. Provisioning computer grabs the submitted file from the USB drives
5. Repeat steps 2-4 ad infinitum


## 1. Creating MAtchStick USBs

This tool installs the operating system with a custom authentication module
(Pluggable Authentication Module; PAM) and provides key management to ensure
that the users can only login once. It also provides the packages to be 
included on the MAtchStick USBs, and customized scripts for student submissions.


### Setup

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

#### Customization

The script is customizable in several ways. First, the main script allows
for a specific password to be used for the disk encryption. The default is
'password', but can be changed by modifying the `CRPYTROOT_PASSWD` variable.

The packages provided are also customizable in the `chroot_installer.sh` file.
The current configuration will provide Java 8 (jre, jdk, doc), Python 3, Vim,
Emacs, and the `midori` web browser for browsing local HTML files. There are
also configurations provided to install Emacs in both scripts.

### Usage

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

## 2. Provisioning Computer

The provisioning computer is designed to assign passwords for login on the MAtchStick 
USBs, and to extract the completed student submissions. A script is provided to 
perform these actions, and is located in the provisioner directory.

### Usage
To use the provisioning script, run ./provision. Upon running it, a menu is presented.
To provision the passwords:
1. Select the first option, 'Password Set'.
2. Ensure none of the USB sticks are plugged into the computer, and press enter
3. Enter the password to provision the USB sticks with
4. Decide if you want the MAtchStick's memory to be wiped on startup (select no
to grant a student re-access to their computer in the event an issue occurred while
they were using their computer the first time)
5. The script will now listen for any newly inserted flash drives, and will
automatically detect and provision them. You may insert any number of flash drives
at a time, and remove them when the command prompt prints out that it is done 
provisioning the drive.
6. Press ctrl-c to exit the provisioning script at any time.

To extract the student submissions from the drive:
1. Select the second option, 'Data Extraction'
2. Ensure none of the USB sticks are plugged into the computer, and press enter
3. The script will now listen for any newly inserted flash drives, and will
automatically detect and grab the files from them. You may insert any number of flash drives
at a time, and remove them when the command prompt prints out that it is done.
4. Press ctrl-c to exit the provisioning script at any time.

## 3. Host Computer
MAtchStick has been tested on numerous computers, and will work on any 
PC that supports UEFI boot. It will also work on any pre-2016 Mac/MacBook.

### Boot Configuration

To configure, if the computer has BIOS, enter the BIOS menu on startup, and 
usually under security or startup, the following options need to be changed:
1. Turn off secure boot.
2. Ensure the boot method is set to some form of UEFI (not legacy). If it is 
currently set to legacy, select uefi with csm, if that is a choice. Otherwise,
select uefi.
3. If desired, change the boot order to first boot off of a USB

Special notes for Windows Surface and select Windows 10 Machines:
1. Before doing anything, Windows Surface has a security tool called bitlocker.
If you adjust any EFI settings without disabling it, you may lose access to your
computer. In the start menu search box, type 'Manage BitLocker', and press enter
2. Follow the steps to back up your recovery key, just in case.
3. Click 'Suspend Protection'
4. Turn off the computer, and enter the UEFI settings by pressing and holding the 
power button and volume-up button, then releasing the power button. Release the
volume button when the surface logo appears.
5. In the boot settings, move USB to the first boot method, and disable secure boot.

NOTE: Step 3 MUST be preformed before EVERY boot into MAtchStick

Instructions for Pre-2017 MacBooks:
1. Turn off secure boot, by following the instructions here:
https://support.apple.com/en-us/HT208330, except choose 'No security', and
'Allow booting from external media'

Special notes for post 2017-MacBook computers:

MacBooks after 2017 don't work with these drives. Upon request, a special
version of these drives may be provided that run OSX and function in the exact
same manner as the Arch MAtchSticks may be provided to accommodate these machines.

### Usage

To use the MAtchSticks, follow the following procedure:

0. If you are on a Surface or other Windows computer with BitLocker, remember to
first Suspend Protection before doing anything.
1. Turn off the computer, and re-turn it on. If the boot order wasn't changed to 
first specify boot from external USB, press the appropriate key to choose the 
USB startup disk (varies by computer)
2. MAtchStick will boot up, and prompt for a password to decrypt. This password
is specified in the install.sh script, under CRYPTROOT_PASSWD
3. Under the login screen, enter the username 'student', and the password
that was set by the provisioning script
4. Once you login, the password is invalidated for future use.
5. Once the work is finished, run the command 'submit'. Running the tool with 
no arguments will bring up the help page. The tool can be run with arguments, 
or interactively. This tool will encrypt the assignment, and place it in a directory
for the provisioning computer to retrieve.
6. Power down the computer.
7. If using a Surface, Secure Boot should be re-enabled by following steps 4 and 5
in the boot configuration step. On other machines, this is optional.


# MAtchStick Security
To ensure security, MAtchStick uses customized encryption protocols that make use
of RSA encryption/signatures, Symmetric Key encryption, and Drive Encryption. These
systems ensure that the user can only log in once, and that the submission originated
from the MAtchStick, not their own personal computer. It also ensures that users
cannot re-provision the drives themselves, nor change the reset-memory property.

# Credits

MAtchStick was developed by Christopher Hittner and Justin Barish.

Copyright 2019 Christopher Hittner and Justin Barish. All Rights Reserved.

