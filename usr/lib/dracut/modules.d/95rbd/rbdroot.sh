#!/bin/sh

#. /lib/rbd-lib.sh


ceph_to_var() {
    local cephuser; local cephpass
    # Check required arguments
    server=${1##ceph://}
    cephuser=${server%@*}
    cephpass=${cephuser#*:}
    if [ "$cephpass" != "$cephuser" ]; then
	cephuser=${cephuser%:*}
    else
	cephpass=$(getarg cephpass)
    fi
    if [ "$cephuser" != "$server" ]; then
	server="${server#*@}"
    else
	cephuser=$(getarg cephuser)
    fi

    path=${server#*/}
    server=${server%:/*}

    if [ ! "$cephuser" -o ! "$cephpass" ]; then
	die "For CEPH support you need to specify a cephuser and cephpass either in the cephuser and cephpass commandline parameters or in the root= CEPH URL."
    fi
    options="name=$cephuser,secret=$cephpass,noatime,nodiratime"
}


[ "$#" = 3 ] || exit 1

# root is in the form root=ceph://user:pass@server:/pool/rbd either from
# cmdline or dhcp root-path
netif="$1"
root="$2"
NEWROOT="$3"

modprobe rbd 2>/dev/null

rbd_to_var $root
echo server: $server
echo options: $options
echo rbd: $pool/$name

# Attempt to map the rbd device.
echo "$server $options $pool $name" > /sys/bus/rbd/add
mount /dev/rbd0 $NEWROOT -o noatime,nodiratime && { [ -e /dev/root ] || ln -s null /dev/root ; }

echo "$server $options $pool $name" > /sys/bus/rbd/add_single_major
mount /dev/rbd0 $NEWROOT -o noatime,nodiratime && { [ -e /dev/root ] || ln -s null /dev/root ; }


# inject new exit_if_exists
echo 'settle_exit_if_exists="--exit-if-exists=/dev/root"; rm -f -- "$job"' > $hookdir/initqueue/ceph.sh
# force udevsettle to break
> $hookdir/initqueue/work

