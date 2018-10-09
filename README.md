# images-odroid-c2

[![Build Status](https://travis-ci.com/Keenwawa/image-odroid-c2.svg?branch=master)](https://travis-ci.com/Keenwawa/image-odroid-c2)

This project produces:
* a full image to be flashable on an SD card for development
* a debarchive and filesystem tarballs mirroring wise-display for it's custom netboot scheme.

## Prerequisites

* Install Virtualbox and Vagrant following instructions from [Local Development Environment](https://keenwawa.atlassian.net/wiki/spaces/Eng/pages/82255985/Local+development+environment).

* Install docker on your system if desired; the vagrant image also installs docker.
  * Docker for Mac link w/o signing up at Docker.com, [here](https://download.docker.com/mac/stable/Docker.dmg)

## Toolchain Environment

The Vagrantfile included in this project is the development environment used
to cross compile package across different platforms.

The choice of build environment base image is based on parity with travis-ci distribution.
Currently, this means Ubuntu 14.04.

This means that, yes, we're running Vagrant, and inside the Vagrant VM, docker
is used as in the internal build environment. Inside the docker container,
a `chroot` is used to setup the ARM binaries.

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

### Building and distributing

To download and build an entire image:

    /vagrant $ make dist

and check the `./dist` directory when the build finishes.  `make build` can be called multiple times and will build as smartly (like not re-downloading files) as it can.

### Odroid-c2

The odroid-c2 environment needs Ubuntu 16.04 LTS Xenial Xerus or higher. This
is accomplished by building a Docker image and running bash through the
container.

#### Make the Docker image

A convience script to create the docker image, `sudo` as necessary:

    $ ./mk_build_env.sh ubuntu-xenial

Or

    $ make docker_image

This script goes into the build-env/ directory, finds the ubuntu-xenial
directory,  and uses the Dockerfile in that subdirectory.

#### Run the image as a container

Using the lower level script to kick off a build:

    $ ./run_build_env.sh ubuntu-xenial

Or

    $ make build

To Debug

    $ ./run_build_env.sh ubuntu-xenial /bin/bash
    # alternatively `make shell`

The containers are set to be deleted when the shell exists, so any work done
outside of mounted directories will be discarded.

If the container isn't cleaned up, do it manually with the docker commands, ex:
(output formatted for better reading)

    $ sudo docker ps
    CONTAINER ID  IMAGE                                          COMMAND     CREATED      STATUS      PORTS NAMES
    2030c8491f70  eatsa-odroid-c2-rootfs:build-env-ubuntu-xenial "/bin/bash" 17 hours ago Up 17 hours       mystifying_kel
    $ docker kill 2030c8491f70

#### Updates to the Dockerfile(s)

If the Dockerfiles are updated, don't forget to stop the containers, delete
the current image, and recreate the build environment.  No image versioning is
scripted at the moment - a future improvement to do.

    $ sudo docker images
    bensonfung@MBP-BensonF ~ $ docker images
    REPOSITORY                TAG                       IMAGE ID            CREATED             SIZE
    eatsa-odroid-c2-rootfs    build-env-ubuntu-xenial   ba3f94d78660        4 days ago          488MB
    eatsa-odroid-c2-rootfs    build-env-ubuntu-bionic   25d2ae25f16f        5 days ago          480MB
    ubuntu                    xenial                    52b10959e8aa        2 weeks ago         115MB
    $ sudo docker rmi ba3f94d78660

### On going maintaince

The built images are stored in https://s3.amazonaws.com/eatsa-artifacts/wise-display/ - clean this directory out regularly as the images built are fairly large and can cost a lot to store many of them.
