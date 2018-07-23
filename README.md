# k8s on Raspbian

Set of Ansible roles deploying k8s on RPI

## Pre-Requisites

### Boot Options

Append to the end of the line in `/boot/cmdline.txt`:

```
cgroup_enable=cpuset cgroup_enable=memory
```

Reboot prior to deploying k8s.

### Docker Pool

Before first booting Raspbian, having provisionned your flash media, make
sure to add a third partition such as our rootfs would have about 8G of
disk space, while the rest of our SD card can be used as a Volume Group:

```
# fdisk /dev/mmcblk0
p
d
2
n
p
2
[start-offset-as-seen-with-p-command]
+8G
n
p
3
[start-offset-as-seen-with-p-command]
[confirm-next-free-offset-is-fine]
[confirm-last-free-offset-is-fine]
w
```

Then, having booted Raspbian:

```
# apt-get update
# apt-get install lvm2
# pvcreate /dev/mmcblk0p3
# vgcreate data /dev/mmcblk0p3
# lvcreate -n docker -l95%VG data
# lvcreate -n dockermeta -l1%VG data
# lvconvert -y --zero n -c 512K \
    --thinpool data/docker \
    --poolmetadata data/dockermeda
```

### Set Hostnames

[duh]

### Enable SSH

[duh]
