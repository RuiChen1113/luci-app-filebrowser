# Copyright 2016 giaulo <giaulo@giaulo.org>
# Copyright 2017 Xingwang Liao <kuoruan@gmail.com>
# This is free software, licensed under the Apache License, Version 2.0

include $(TOPDIR)/rules.mk

LUCI_TITLE:=Luci file browser
LUCI_DEPENDS:=
LUCI_PKGARCH:=all

include ../../luci.mk

# call BuildPackage - OpenWrt buildroot signature
