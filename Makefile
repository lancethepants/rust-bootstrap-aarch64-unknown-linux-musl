export DESTARCH=aarch64
export PREFIX=/mmc

export EXTRACFLAGS = -mcpu=cortex-a53
export PATH := /opt/tomatoware/$(DESTARCH)$(subst /,-,$(PREFIX))/bin/:$(PATH)

rust:
	./scripts/rust.sh

clean:
	git clean -fdxq && git reset --hard
