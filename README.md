# k8s on Raspbian

Set of Ansible roles deploying k8s on RPI.

Last tested with raspbian buster 10.3, k8s 1.17.3, on armv7l/v8l.

## Configuration

Set proper hostnames, enable SSH, install python-apt.

Update `hosts`, `group_vars` & `host_vars`.

## Deployment

Prepare cluster variables, in `group_vars/all.yml`, then deploy cluster:

```
$ ansible-playbook -i hosts ./k8s.yml
```

## Notes

### Multi-Master

Note multi-master deployment is not operational - this could be done with
the following manual steps:

- edit k8s role, do not load join tasks, stop after initializing first
  master.
- apply `rpi`/`containers`/`k8s` roles to all masters
- once cluster is initialized on a first master, run the join command from
  an other one
- connect etcd on the initial master, add new member (`etcdctl member add`)
- edit `/etc/kubernetes/manifests/etcd.yaml` on initial master, notice that
  while our init script should have set a proper URL, the
  `initial-cluster-members` param only mentions our initial master: fix it
  to include all 3 members - beware, restarting etcd, going from 1 to 3
  members: quorum would be broken until our second member joins in, k8s API
  would blink, ... that shouldn't take long. though make sure you did run
  the firt join command *before* reconfiguring etcd.
- once etcd is back up, we may join our last master, and add it to etcd as well
- generate new kube-apiserver certificates for additional masters
  (see `roles/k8s/templates/post-init.j2` -- arguably, consider generating
  a unique apiserver certificate whose SAN covers all masters)
- next, scale out `controllers`/`apiserver`/`scheduler` Pods to all masters (see
  `roles/k8s/templates/post-init.j2`), consider fixing addresses in
  `/etc/kubernetes/(admin|scheduler|controller-manager|kubelet).conf`. Not sure
  what's best -- in my case, I have 3 racks of 4 RPIs: kubelets from rack N
  would connect to whichever master is on the same rack, masters services in
  general rely on locally hosted services. In most cases, you may just want to
  use your LB address, some VIP, a DNS record resolving to all masters, ...
  Either way, make your re-generate the API server certificate with proper SAN.

### Crio

Note that cri-o runtime does not seem to work with kubernetes, when running
with systemd cgroups driver. Turns out container would fail to start applying
CPU quotas. On raspbian, we should expect those sysctls [to be missing](https://raspberrypi.stackexchange.com/questions/87779/missing-cpu-cfs-period-us-cgroup-subsystem-in-raspbian-stretch-on-raspberry-pi-z).

Docker also complains about those, yet shows it as a warning and still starts
containers - whereas I could not start etcd, initializing my first master with
Crio. A workaround may be to build your own kernel. Wait for a fix. Note I
haven't tried the cgroupfs driver. Testing docker, I did use the systemd driver
as well.

### Docker Pool

Only applies when using Docker runtime. And even then: not mandatory.

Before first booting Raspbian, having provisionned our flash media, we may
add a separate partition, such as our rootfs would have about 8G of
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

On masters, consider creating a LV hosting etcd.

## Special Thanks

Special thanks to:

 * Anne Fernandes
 * Dimitris Finas
 * Nicolas Fleury-Gobert
