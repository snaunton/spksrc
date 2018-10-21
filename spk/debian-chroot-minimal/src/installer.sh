#!/bin/sh

# Package
PACKAGE="debian-chroot-minimal"
DNAME="Debian Chroot Minimal"

# Others
INSTALL_DIR="/usr/local/${PACKAGE}"
CHROOTTARGET="${INSTALL_DIR}/var/chroottarget"
TMP_DIR="${SYNOPKG_PKGDEST}/../../@tmp"

preinst ()
{
    exit 0
}

postinst ()
{
    # Link
    ln -s ${SYNOPKG_PKGDEST} ${INSTALL_DIR}

    # Debootstrap second stage in the background and configure the chroot environment
    if [ "${SYNOPKG_PKG_STATUS}" != "UPGRADE" ]; then
        chroot ${CHROOTTARGET}/ /debootstrap/debootstrap --second-stage > /dev/null 2>&1 && \
            mv ${CHROOTTARGET}/etc/apt/sources.list.default ${CHROOTTARGET}/etc/apt/sources.list && \
            mv ${CHROOTTARGET}/etc/apt/preferences.default ${CHROOTTARGET}/etc/apt/preferences && \
            touch ${INSTALL_DIR}/var/installed &
        chmod 666 ${CHROOTTARGET}/dev/null
        chmod 666 ${CHROOTTARGET}/dev/tty
        chmod 777 ${CHROOTTARGET}/tmp
        cp /etc/hosts /etc/hostname /etc/resolv.conf ${CHROOTTARGET}/etc/
    fi

    exit 0
}

check_stopped ()
{
    grep -q "$(realpath "${CHROOTTARGET}")" /proc/mounts || return

    echo "${DNAME} is not completely stopped. Please check that all its mounts underneath ${CHROOTTARGET} have been umounted." >> $SYNOPKG_TEMP_LOGFILE
    exit 1
}

preuninst ()
{
    check_stopped
    exit 0
}

postuninst ()
{
    # Remove link
    rm -f ${INSTALL_DIR}

    exit 0
}

preupgrade ()
{
    check_stopped

    # Save some stuff
    rm -fr ${TMP_DIR}/${PACKAGE}
    mkdir -p ${TMP_DIR}/${PACKAGE}
    mv ${INSTALL_DIR}/var ${TMP_DIR}/${PACKAGE}/

    exit 0
}

postupgrade ()
{
    # Restore some stuff
    rm -fr ${INSTALL_DIR}/var
    mv ${TMP_DIR}/${PACKAGE}/var ${INSTALL_DIR}/
    rm -fr ${TMP_DIR}/${PACKAGE}

    exit 0
}

