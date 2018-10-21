#!/bin/sh

# Package
PACKAGE="debian-chroot-minimal"
DNAME="Debian Chroot Minimal"

# Others
INSTALL_DIR="/usr/local/${PACKAGE}"
PATH="${INSTALL_DIR}/bin:${PATH}"
CHROOTTARGET=$(realpath "${INSTALL_DIR}/var/chroottarget")
BIND_MOUNTS=$(realpath "${INSTALL_DIR}/etc/bind-mounts")
SERVICES=$(realpath "${INSTALL_DIR}/etc/services")

# Make up to ATTEMPTS attempts to umount $@
# Return 0 if successful, 1 if not
umount_do () {
    ATTEMPTS=10

    while [ $ATTEMPTS -ge 0 ]; do
        umount "$@"
        grep -q "$@ " /proc/mounts || return 0
        sleep 1
        let "(ATTEMPTS -= 1)"
    done
    return 1
}

bind_mounts_mount ()
{
    sed -e 's/#.*$//' -e '/^\s*$/d' "${BIND_MOUNTS}" | while read MOUNT; do
        TARGET="$(echo ${MOUNT} | awk -v FPAT="([^ ]+)|(\"[^\"]+\")" '{print $2}')"
        grep -q "$(realpath "${TARGET}") " /proc/mounts || mount --bind ${MOUNT}
    done
}

bind_mounts_umount ()
{
    RC=0
    tac "${BIND_MOUNTS}" | sed -e 's/#.*$//' -e '/^\s*$/d' | while read MOUNT; do
        TARGET="$(echo ${MOUNT} | awk -v FPAT="([^ ]+)|(\"[^\"]+\")" '{print $2}')"
        umount_do "${TARGET}" || RC=1
    done
    return $RC
}

services_start ()
{
    sed -e 's/#.*$//' -e '/^\s*$/d' "${SERVICES}" | while read SERVICE; do
        chroot "${CHROOTTARGET}/" /bin/bash -c "${SERVICE} status" || chroot "${CHROOTTARGET}/" /bin/bash -c "${SERVICE} start"
    done
}

services_stop ()
{
    tac "${SERVICES}" | sed -e 's/#.*$//' -e '/^\s*$/d' | while read SERVICE; do
        chroot "${CHROOTTARGET}/" /bin/bash -c "${SERVICE} status" && chroot "${CHROOTTARGET}/" /bin/bash -c "${SERVICE} stop"
    done
}

start_daemon ()
{
    # Return if install is not finished
    if [ ! -f "${INSTALL_DIR}/var/installed" ]; then
        echo "${DNAME} is still being installed in the background." >> $SYNOPKG_TEMP_LOGFILE
        echo "This can take some time." >> $SYNOPKG_TEMP_LOGFILE
        echo "Please try again later." >> $SYNOPKG_TEMP_LOGFILE
        return
    fi

    # Run any pre start scripts
    run-parts "${INSTALL_DIR}/etc/prestart.d"

    # Mount user defined mounts
    bind_mounts_mount

    # Mount chroot mounts. Make sure we don't mount twice
    grep -q "${CHROOTTARGET}/proc " /proc/mounts || mount -t proc proc "${CHROOTTARGET}/proc"
    grep -q "${CHROOTTARGET}/sys " /proc/mounts || mount -t sysfs sys "${CHROOTTARGET}/sys"
    grep -q "${CHROOTTARGET}/dev " /proc/mounts || mount -o bind /dev "${CHROOTTARGET}/dev"
    grep -q "${CHROOTTARGET}/dev/pts " /proc/mounts || mount -o bind /dev/pts "${CHROOTTARGET}/dev/pts"

    # Start user defined services
    services_start
}

stop_daemon ()
{
    # Stop user defined services
    services_stop

    # Give user defined services a chance to stop
    sleep 1

    # kill -TERM any processes running under the chroot
    # Then kill -KILL any remaining after that
    # This is to help make sure any chroot related mounts are not busy
    for SIG in "" -9; do
        for R in /proc/*/root; do
            [ "$(readlink $R)" = "${CHROOTTARGET}" ] && kill ${SIG} $(echo ${R} | cut -f3 -d"/");
        done
        sleep 1
    done

    # Unmount chroot mounts. Note that for the sake of efficiency /dev/pts should
    # be first and /dev last to give umount /dev/pts a chance to finish before
    # attempting to umount /dev
    RC=0
    umount_do "${CHROOTTARGET}/dev/pts" || RC=1
    umount_do "${CHROOTTARGET}/sys" || RC=1
    umount_do "${CHROOTTARGET}/proc" || RC=1
    umount_do "${CHROOTTARGET}/dev" || RC=1

    # Unmount any user defined mounts
    bind_mounts_umount || RC=1

    sleep 1

    # Force umount of anything mounted under the chroot
    grep "${CHROOTTARGET}" /proc/mounts | awk -v FPAT="([^ ]+)|(\"[^\"]+\")" '{print $2}' | sort -r | while read TARGET; do
        umount -f "${TARGET}"
    done

    sleep 1

    # Run any post stop scripts
    run-parts "${INSTALL_DIR}/etc/poststop.d"

    # Make sure we return non-zero if there are any mounts that failed to umount
    return $RC
}

daemon_status ()
{
    grep -q "${CHROOTTARGET}/proc " /proc/mounts \
        && grep -q "${CHROOTTARGET}/sys " /proc/mounts \
        && grep -q "${CHROOTTARGET}/dev " /proc/mounts \
        && grep -q "${CHROOTTARGET}/dev/pts " /proc/mounts
}

case $1 in
    start)
        if daemon_status; then
            echo ${DNAME} is already running
            exit 0
        else
            echo Starting ${DNAME} ...
            start_daemon
            exit $?
        fi
        ;;
    stop)
        if daemon_status; then
            echo Stopping ${DNAME} ...
            stop_daemon
            exit $?
        else
            echo ${DNAME} is not running
            exit 0
        fi
        ;;
    status)
        if daemon_status; then
            echo ${DNAME} is running
            exit 0
        else
            echo ${DNAME} is not running
            exit 1
        fi
        ;;
    chroot)
        chroot ${CHROOTTARGET}/ /bin/bash
        ;;
    *)
        exit 1
        ;;
esac
