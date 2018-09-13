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
    set -e
    sudo DEBIAN_FRONTEND=noninteractive apt-get update
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y git curl

    if ! sudo apt-key list | grep 0EBFCD88; then
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
        if ! sudo apt-key list | grep 0EBFCD88; then
            echo "Could not find docker.com's fingerprint 0EBFCD88."
            exit 1;
        fi
        sudo add-apt-repository \
"deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
        sudo DEBIAN_FRONTEND=noninteractive apt-get update
    fi

    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y docker-ce
    sudo DEBIAN_FRONTEND=noninteractive apt-get -y autoremove

    # allow vagrant user docker access w/o sudo
    if ! grep docker /etc/group; then
        sudo groupadd docker
    fi
    if ! groups vagrant | grep docker; then
        sudo usermod -a -G docker vagrant
    fi
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
    set -e

    if [ ! -e "#{package_cache}" ]; then
        echo "Downloading #{package_url}"
        curl -Ss #{package_url} -o #{package_cache} > /dev/null

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

  # Run build-scripts/build-setup to get tools
  config.vm.provision 'shell', path: 'build-scripts/build-setup.sh'
end
