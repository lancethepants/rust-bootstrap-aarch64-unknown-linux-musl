export DESTARCH=aarch64
export PREFIX=/mmc

export EXTRACFLAGS = -mcpu=cortex-a53
export PATH := $(PATH):/opt/tomatoware/aarch64-musl$(subst /,-,$(PREFIX))/bin/

rust:
	./scripts/rust.sh

clean:
	git clean -fdxq && git reset --hard
