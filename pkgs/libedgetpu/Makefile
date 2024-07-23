
# From https://github.com/NixOS/nixpkgs/issues/188719#issuecomment-2094575860
all: libedgetpu.so.1.0

libedgetpu.so.1.0:
	git clone https://github.com/google-coral/libedgetpu.git
	cd libedgetpu && \
	git checkout e35aed18fea2e2d25d98352e5a5bd357c170bd4d && \
	sed -i 's/SHELL := \/bin\/bash/SHELL := bash/g' Makefile && \
	DOCKER_CPUS="k8" DOCKER_IMAGE="ubuntu:22.04" DOCKER_TARGETS=libedgetpu make docker-build && \
	DOCKER_CPUS="armv7a aarch64" DOCKER_IMAGE="debian:bookworm" DOCKER_TARGETS=libedgetpu make docker-build && \
	cp out/direct/k8/libedgetpu.so.1.0 ..

clean:
	rm -rf libedgetpu