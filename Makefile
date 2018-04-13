MOPTS			?= -j1
CFLAGS			?= -O2
CPPFLAGS		?= -O2

VERSION			?= latest

USERNAME		?= g0dscookie
SERVICE			?= postfix
TAG				= $(USERNAME)/$(SERVICE)

.PHONY: build
build:
	MAKEOPTS="$(MOPTS)" CFLAGS="$(CFLAGS)" CPPFLAGS="$(CPPFLAGS)" ./build.py --debug --version $(VERSION)

.PHONE: build-all
build-all:
	MAKEOPTS="$(MOPTS)" CFLAGS="$(CFLAGS)" CPPFLAGS="$(CPPFLAGS)" ./build.py --debug --version all

.PHONY: push
push:
	docker push $(TAG)