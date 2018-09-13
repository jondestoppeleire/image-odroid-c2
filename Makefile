SCRIPTS = $(shell find . -type f -name "*.sh" -not -path "./workspace/*" -not -path "./dist/*")

# depends on shellcheck 0.4.6+.  Will fail on 0.3.3.
.PHONY: shellcheck
shellcheck: docker_image
	docker run --rm -it -e HOME --privileged \
     -h eatsa-odroid-c2-build-env \
     -v "$$HOME":"$$HOME" \
     -v "$$PWD":"$$PWD" -w "$$PWD" \
     eatsa-odroid-c2-rootfs:build-env-ubuntu-xenial \
     shellcheck $(SCRIPTS)

.PHONY: docker_image
docker_image:
	./mk_build_env.sh ubuntu-xenial

.PHONY: build
build: docker_image
	DEBUG=1 ./run_build_env.sh ubuntu-xenial
