#!/bin/sh

if test -z "$1"; then
    NETIF=$(ip link show | awk '/^[^ ]/{if ($2 != "lo:") {print $2;exit;}}' | cut -d: -f1)
else
    NETIF=$1
fi
if test -z "$NETIF"; then
    NETIF=eth0
fi
if test -s /run/flannel/subnet.env -a "$NETIF"; then
    . /run/flannel/subnet.env
    ME=$(ip a show $NETIF | awk '/inet/{print $2;exit;}' | cut -d/ -f1)

    if test "$FLANNEL_SUBNET" -a "$ME" -a "$FLANNEL_NETWORK"; then
	if ! iptables -t nat -nL 2>/dev/null | grep $ME \
		| grep $FLANNEL_SUBNET | grep $FLANNEL_NETWORK \
		>/dev/null; then
	    iptables -t nat -A POSTROUTING \
		-o $NETIF \
		-s $FLANNEL_SUBNET \
		! -d $FLANNEL_NETWORK \
		-j SNAT \
		--to-source $ME
	else
	    exit 0
	fi
	exit $?
    fi
fi

exit 1
