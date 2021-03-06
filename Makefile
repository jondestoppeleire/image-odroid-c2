SCRIPTS = $(shell find . -type f -name "*.sh" -not -path "./workspace/*" -not -path "./dist/*")
SHELL_FILES = base-files/eatsa-user/etc/X11/Xsession.d/80x11-wise-xsession \
	base-files/boot-customization/usr/share/initramfs-tools/hooks/eatsa-initrd-hook
BASH_FILES = base-files/base-system/etc/network/if-up.d/wise-ifpreup-hostname \
	base-files/base-system/etc/network/if-up.d/wise-ifup-hostname \
	base-files/eatsa-user/home/eatsa/.profile

# depends on shellcheck 0.4.6+.  Will fail on 0.3.3.
.PHONY: shellcheck
shellcheck: build_setup
	 /bin/bash -c "shellcheck $(SCRIPTS) && shellcheck -s sh $(SHELL_FILES) && shellcheck -s bash $(BASH_FILES)"

.PHONY: build_setup
build_setup:
	./build-scripts/build-setup.sh

.PHONY: docker_image
docker_image: build_setup
	./mk_build_env.sh ubuntu-xenial

.PHONY: build
build: shellcheck docker_image
	./run_build_env.sh ubuntu-xenial

.PHONY: dist
dist: build
	./run_build_env.sh ubuntu-xenial ./dist_full_img.sh

.PHONY: dist_only
dist_only:
	./run_build_env.sh ubuntu-xenial ./dist_full_img.sh

.PHONY: shell
shell: docker_image
	./run_build_env.sh ubuntu-xenial /bin/bash

.PHONY: clean
clean:
	rm -rf workspace

# experimental
.PHONY: docker_image_bionic
docker_image_bionic: build_setup
	./mk_build_env.sh ubuntu-bionic

# Bionic build seems to hang with platform specific issue
# a similar issue is https://forum.armbian.com/topic/6420-preparing-for-ubuntu-1804/
.PHONY: build_bionic
build_bionic: docker_image_bionic
	./run_build_env.sh ubuntu-bionic

.PHONY: shell_bionic
shell_bionic:
	./run_build_env.sh ubuntu-bionic /bin/bash
