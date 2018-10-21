SPK_NAME = debian-chroot-minimal
SPK_VERS = 9.5
SPK_REV = 1
SPK_ICON = src/debian.png

BETA = 1

DEPENDS =

MAINTAINER = snaunton
DESCRIPTION = Debian is a free operating system \(OS\) that comes with over 29000 packages, precompiled software bundled up in a nice format for easy installation on your DiskStation. Debian Chroot allows you to benefit from the Debian OS inside your DiskStation, alongside DSM. This package is intended for advanced users only.
DESCRIPTION_FRE = Debian est un système d\'exploitation \(SE\) qui rend disponible plus de 29000 paquets, logiciels précompilés et empaquetés dans un joli format pour rendre son installation facile sur votre DiskStation. Debian Chroot vous permet de bénéficier du SE Debian au sein de votre DiskStation, aux cotés de DSM. Ce paquet est destiné aux utilisateurs avancés uniquement.
DISPLAY_NAME = Debian Chroot Minimal
CHANGELOG = "Initial"

HOMEPAGE = http://www.debian.org
LICENSE  = https://www.debian.org/legal/licenses
HELPURL  = https://github.com/SynoCommunity/spksrc/wiki/Debian-Chroot-Minimal

INSTALLER_SCRIPT = src/installer.sh
SSS_SCRIPT       = src/dsm-control.sh

INSTALL_PREFIX = /usr/local/$(SPK_NAME)

COPY_TARGET = debian-chroot-minimal_copy_target
POST_STRIP_TARGET = debian-chroot-minimal_extra_install

DEBIAN_ARCH =
ifeq ($(findstring $(ARCH),88f6281),$(ARCH))
DEBIAN_ARCH = armel
endif
ifeq ($(findstring $(ARCH),alpine armada370 armada375 armada38x armadaxp monaco),$(ARCH))
DEBIAN_ARCH = armhf
endif
ifeq ($(findstring $(ARCH),evansport),$(ARCH))
DEBIAN_ARCH = i386
endif
ifeq ($(findstring $(ARCH),braswell bromolow cedarview x86 avoton x64),$(ARCH))
DEBIAN_ARCH = amd64
endif
ifeq ($(findstring $(ARCH),qoriq),$(ARCH))
DEBIAN_ARCH = powerpc
endif
ifeq ($(strip $(DEBIAN_ARCH)),)
$(error Arch $(ARCH) not supported)
endif

include ../../mk/spksrc.spk.mk

.PHONY: debian-chroot-minimal_copy_target
debian-chroot-minimal_copy_target1:


.PHONY: debian-chroot-minimal_extra_install
debian-chroot-minimal_extra_install:
	install -m 755 -d $(STAGING_DIR)/var
	install -m 755 -d $(STAGING_DIR)/etc/prestart.d
	install -m 755 -d $(STAGING_DIR)/etc/poststop.d
	install -m 644 src/bind-mounts $(STAGING_DIR)/etc/bind-mounts
	install -m 644 src/services $(STAGING_DIR)/etc/services
	install -m 644 src/README $(STAGING_DIR)/README
	debootstrap --foreign --arch $(DEBIAN_ARCH) stretch $(STAGING_DIR)/var/chroottarget "http://ftp.debian.org/debian"
	install -m 644 src/sources.list $(STAGING_DIR)/var/chroottarget/etc/apt/sources.list.default
	install -m 644 src/preferences $(STAGING_DIR)/var/chroottarget/etc/apt/preferences.default
	install -m 644 src/policy-rc.d $(STAGING_DIR)/var/chroottarget/usr/sbin/policy-rc.d
