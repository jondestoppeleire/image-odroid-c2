# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.require_version ">= 2.1.2", "< 2.2.0"

Vagrant.configure('2') do |config|
  # Use trusty as our build environment as that is the latest version
  # available to travis-ci as of 2018 August.
  config.vm.box = 'ubuntu/trusty64'

  # Disable automatic box update checking. If you disable this, then
  # boxes will only be checked for updates when the user runs
  # `vagrant box outdated`. This is not recommended.
  # config.vm.box_check_update = false
  config.vm.provider 'virtualbox' do |vb|
    vb.memory = "4096"
    vb.customize ['modifyvm', :id, '--memory', '4096']
    vb.customize ['modifyvm', :id, '--cpus', '4']
    vb.customize ['modifyvm', :id, '--hwvirtex', 'on']
    vb.customize ['modifyvm', :id, '--audio', 'none']
    vb.customize ['modifyvm', :id, '--vram', '16']
    vb.customize ['modifyvm', :id, '--vrde', 'off']
  end

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  config.vm.synced_folder '.', '/vagrant'

  # Install tools that travis already has: git, curl, and docker-ce
  # see https://docs.docker.com/install/linux/docker-ce/ubuntu/
  config.vm.provision 'shell', inline: <<-SHELL
    #!/bin/bash
    sudo DEBIAN_FRONTEND=noninteractive apt-get update || exit 1
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y git curl || exit 1

    if ! sudo apt-key list | grep 0EBFCD88; then
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - || exit 1
        if ! sudo apt-key list | grep 0EBFCD88; then
            echo "Could not find docker.com's fingerprint 0EBFCD88."
            exit 1;
        fi
        sudo add-apt-repository \
"deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" || exit 1
        sudo DEBIAN_FRONTEND=noninteractive apt-get update || exit 1
    fi

    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y docker-ce || exit 1
    sudo DEBIAN_FRONTEND=noninteractive apt-get -y autoremove || exit 1
  SHELL

  # .travis.yml:
  #
  # before_install:
  #   download and install build-framework
  build_framework_package = 'build-framework-master-1.5.0.tgz'
  package_url = "https://s3.amazonaws.com/eatsa-packages/build-framework/#{build_framework_package}"
  package_cache = "/tmp/#{build_framework_package}"
  extract_dir = '/home/vagrant/bf'

  config.vm.provision 'shell', inline: <<-SHELL
    #!/bin/bash

    if [ ! -e "#{package_cache}" ]; then
        echo "Downloading #{package_url}"
        curl -s #{package_url} -o #{package_cache} > /dev/null

        if [ ! -s "#{package_cache}" ]; then
            echo "Error downloading to #{package_cache}"
            exit 1
        fi
    fi

    # oddly, extracting build-framework directly into /home/vagrant nukes some
    # files that allow `vagrant ssh` to work correctly.
    # We'll extract build-framework into /home/vagrant/bf directory first
    # and make a symlink:
    #     /home/vagrant/build-framework -> /home/vagrant/bf/build-framework
    if [ -s "#{package_cache}" ] && [ ! -d "#{extract_dir}" ]; then
      echo "Extracting #{package_cache} ..."
      mkdir -p "#{extract_dir}" && tar xzf "#{package_cache}" --directory "#{extract_dir}"
      sudo chown -R vagrant:vagrant "#{extract_dir}"
    fi

    # create build-framework symlink if not exist.
    if [ ! -e build-framework ] && [ -d "#{extract_dir}" ]; then
      ln -s "#{extract_dir}/build-framework" build-framework
    fi

    echo "Done."
  SHELL

  # Add the project to the home directory
  #
  # Running `sudo ./utils/mk_filesystem_artifact.sh...` inside the mounted dir
  # /vagrant doesn't work, as the script uses chroot and that seems to run
  # into odd permissions / access issues.
  #
  # So.  We'll copy /vagrant into /home/vagrant/wise-display.  In a travis-ci
  # build, the project is not run in a specially mounted dir anyways, so this
  # makes travis-ci parity actually better.
  config.vm.provision 'shell', inline: <<-SHELL
    #!/bin/bash

    if [ -d /vagrant ] && [ ! -d /home/vagrant/wise-display ]; then
      mkdir -p /home/vagrant/wise-display

      # copy files over excluding those specified in .gitignore.
      # This will prevent copying artifacts (large) produced from being copied.
      # However, we still need the .git directory due to build-framework and other scripts.
      #
      # shellcheck disable=SC2010 - much harder to use `find` w/right format.
      for node in $(ls -1 /vagrant | grep -vxf /vagrant/.gitignore) .git; do
        cp -R "/vagrant/$node" "/home/vagrant/wise-display/$node"
      done
    fi

    # Set the owner of /home/vagrant/wise-display
    if [ -d /home/vagrant/wise-display ] && \
       [ "$(stat -c "%U:%G" /home/vagrant/wise-display)" != "vagrant:vagrant" ]; then
         sudo chown -R vagrant:vagrant /home/vagrant/wise-display
    fi
  SHELL
end
