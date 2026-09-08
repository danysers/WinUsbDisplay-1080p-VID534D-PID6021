# SPDX-License-Identifier: GPL-2.0-only
KVER ?= $(shell uname -r)
KSRC ?= /lib/modules/$(KVER)/build
.PHONY: all modules clean
all: modules
modules:
	$(MAKE) -C $(KSRC) M=$(CURDIR) modules
clean:
	$(MAKE) -C $(KSRC) M=$(CURDIR) clean
