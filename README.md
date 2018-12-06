# images-odroid-c2

[![Build Status](https://travis-ci.com/Keenwawa/image-odroid-c2.svg?branch=master)](https://travis-ci.com/Keenwawa/image-odroid-c2)

This project produces:
* a full image to be flashable on an SD card for development
* a debarchive and filesystem tarballs mirroring wise-display for it's custom netboot scheme.

## Prerequisites

* Install Virtualbox and Vagrant following instructions from [Local Development Environment](https://keenwawa.atlassian.net/wiki/spaces/Eng/pages/82255985/Local+development+environment).

## Toolchain Environment

The Vagrantfile included in this project is the development environment used
to cross compile package across different platforms.

The choice of build environment base image is based on parity with travis-ci distribution.
Currently, the base OS used is Ubuntu 14.04.

The actual OS built is an Ubuntu 16.04 image. To use the tools compatible with
the target OS version, Ubuntu 16.04 is run in a docker container to build the
target OS.

TL;DR:

Vagrant (Ubuntu 14.04)
 |-- Docker (Ubuntu 16.04)
      |-- /vagrant/workspace/rootfs (chroot, for ARM64)

### Upgrading

* Stop and delete any vagrant instances running:

      $ vagrant halt && vagrant destroy -f

* Update the Vagrantfile with the new vagrant box.
* Execute `vagrant up`.
* Test the new environment.

## Development

Take a deep breath.  Patience.

Vagrant is used to simulate the travis VM.

    $ vagrant up
    $ vagrant ssh
    $ ls /vagrant

The Vagrant file should run `/vagrant/build-scripts/build-setup` automatically to install all the tools needed to build the cross compilation environmnt.

### Building

To download and build an entire image:

    $ cd /vagrant
    $ make dist

and check the `./dist` directory when the build finishes.  `make build` can be called multiple times and will build as smartly (like not re-downloading files) as it can.

### Distribution

The end distributables can be found in S3 with the appropriate permissions.

| AWS Account       | Techops                         |
|-------------------|---------------------------------|
| S3 Bucket         | eatsa-artifacts                 |
| Folder            | wise-display                    |
| filename prefix   |                                 |
|   upgrade package | filesystem-smartshelf-odroid_c2 |
|   full flash img  | eatsa-smartshelf-odroid-c2      |

The image filenames are suffixed with a UTC timestamp of the build.
A sha256sum file is provided as well.

#### Dependencies

This current build depends on the [fw-smartshelf](https://github.com/Keenwawa/fw-smartshelf) project.
The artifacts of that project are built and pulled from S3 in the folder: `eatsa-artifacts/fw-smartshelf/process_controller-*.tgz`.

#### Downstream Depdencies

[wise-display](https://github.com/Keenwawa/wise-display) has a dependency on images produced stored in the S3 bucket. See [wise-display/build-scripts/build-install](https://github.com/Keenwawa/wise-display/blob/master/build-scripts/build-install).

#### Flashing onto SD Card

For development, flash the full image to a SD Card. Recommendto use [Etcher](https://www.balena.io/etcher/).
Download the latest image and use Etcher to flash it on an SD card.

**The required minimum SD card size is 8GB.**

#### Over The Air (OTA) updates

Over the Air (OTA) updates is used to describe upgrading embedded linux distributions.

This build of a smartshelf OS for odroid-c2 uses a Dual Copy update strategy.
The Dual Copy strategy uses an active and an inactive disk partition.  Updates
are written to the inactive partition and swapped to upon reboot of the device.

The benefits of this scheme is that the updates can be done in user space and allows current processes to be running. This allows debugging to be much easier, and hanging devices in the wild can be fixed in a easier way.

This scheme differs from the current NUC i5x and ODROID XU4 code seen in their builds in wise-display.

##### Partitioning scheme

The Dual Copy update strategy utilized 4 partitions.

1. Normal boot partition
   * `/dev/mmcblk0p1`
   *  Mounted on `/media/boot` on odroid-c2.
2. An active partition
   * `/dev/mmcblk0p2`, initial active partition.
   * Mounted on `/`
3. Inactive partition
   * `/dev/mmcblk0p3`, initial inactive partition.
   * Not Mounted!
4. Data partition
   * `/dev/mmcblk0p4`
   * Mounted on `/media/data`
   * Used to store the latest filesystem archive (`.squashfs` file)

##### Update process

Available through supervisord, the following script performs the upgrade.

`/usr/local/bin/wise-upgrade.sh`:
1. Detect and download latest `.squashfs.sha256sum` file.
2. Download latest `.squashfs` file referenced by `.squashfs.sha256sum` file.
3. Compare `/version.txt` to the UTC timestamp in downloaded filename.
4. If versions differ, unsquash and mount `.squashfs` file to `/media/rootfs_pX`, where X is the inactive partiion #.
5. Update `fstab` file on inactive partition.
6. Update `/media/boot/boot.ini` to boot with the updated partition.

Reboot to use the update.  Run the script again to swap partitions, with or without updates.

The scripts are available through the supervisord web interface.

References:
* [Updating Embedded Linux Devices: Update strategies](https://mkrak.org/2018/01/10/updating-embedded-linux-devices-part1/)
