SCRIPTS = $(shell find . -type f -name "*.sh" -not -path "./workspace/*" -not -path "./dist/*")
CHECK_EM = base-files/eatsa-user/etc/X11/Xsession.d/80x11-wise-xsession

# depends on shellcheck 0.4.6+.  Will fail on 0.3.3.
.PHONY: shellcheck
shellcheck: docker_image
	docker run --rm -it -e HOME --privileged \
	 -h eatsa-odroid-c2-build-env \
	 -v "$$HOME":"$$HOME" \
	 -v "$$PWD":"$$PWD" -w "$$PWD" \
	 eatsa-odroid-c2-rootfs:build-env-ubuntu-xenial \
	 /bin/bash -c "shellcheck $(SCRIPTS) && shellcheck -s sh $(CHECK_EM)"

.PHONY: docker_image
docker_image:
	./mk_build_env.sh ubuntu-xenial

.PHONY: build
build: docker_image
	./run_build_env.sh ubuntu-xenial

.PHONY: shell
shell: shellcheck
	./run_build_env.sh ubuntu-xenial /bin/bash

# experimental
.PHONY: docker_image_bionic
docker_image_bionic:
	./mk_build_env.sh ubuntu-bionic

# Bionic build seems to hang with platform specific issue
# a similar issue is https://forum.armbian.com/topic/6420-preparing-for-ubuntu-1804/
.PHONY: build_bionic
build_bionic: docker_image_bionic
	./run_build_env.sh ubuntu-bionic

.PHONY: shell_bionic
shell_bionic:
	./run_build_env.sh ubuntu-bionic /bin/bash
