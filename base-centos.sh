#!/bin/bash
#
## base.sh
## (c) 2020:01:15::ml4
## Injection script for packer to run on the nascent machine image to set up fstab _et al_
## Opinionated hardening
#
###########################################################################################

function log {
  local -r level="$1"
  local -r message="$2"
  local -r timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  >&2 echo -e "${timestamp} [${level}] ${message}" | sudo tee -a /root/base.log
}

export C="###########################################################################################"

cd /
echo
##################################################################################################
echo "${C}"
echo "## Base image preparation."
echo "#"
echo -n "Running parted..."
for i in f g h i j
do 
  sudo parted -s /dev/xvd${i} mklabel gpt
  rCode=${?}
  if [ ${rCode} -gt 0 ]
  then
    log "ERROR" "sudo parted -s /dev/xvd${i} mklabel gpt failed"
    exit ${rCode}
  fi
done

for i in f g h i j
do 
  sudo parted -s -a optimal  -- /dev/xvd${i} mkpart primary xfs 0% 100%
  rCode=${?}
  if [ ${rCode} -gt 0 ]
  then
    log "ERROR" "sudo parted -s -a optimal  -- /dev/xvd${i} mkpart primary xfs 0% 100% failed"
    exit ${rCode}
  fi
done
echo 'done'

echo 'Creating filesystems...'
for i in f g h i j
do 
  sudo mkfs -t xfs -f /dev/xvd${i}1
  rCode=${?}
  if [ ${rCode} -gt 0 ]
  then
    log "ERROR" "sudo mkfs -t xfs -f /dev/xvd${i}1 failed"
    exit ${rCode}
  fi
done

echo
echo -n 'Building directory structure...'
sudo mkdir -p /mnt/myroot/var
rCode=${?}
if [ ${rCode} -gt 0 ]
then
  log "ERROR" "sudo mkdir -p /mnt/myroot/var failed"
  exit ${rCode}
fi

sudo mkdir -p /mnt/myroot/var-tmp
rCode=${?}
if [ ${rCode} -gt 0 ]
then
  log "ERROR" "sudo mkdir -p /mnt/myroot/var-tmp failed"
  exit ${rCode}
fi

sudo mkdir -p /mnt/myroot/var-log
rCode=${?}
if [ ${rCode} -gt 0 ]
then
  log "ERROR" "sudo mkdir -p /mnt/myroot/var-log failed"
  exit ${rCode}
fi

sudo mkdir -p /mnt/myroot/var-log-audit
rCode=${?}
if [ ${rCode} -gt 0 ]
then
  log "ERROR" "sudo mkdir -p /mnt/myroot/var-log-audit failed"
  exit ${rCode}
fi

sudo mkdir -p /mnt/myroot/home
rCode=${?}
if [ ${rCode} -gt 0 ]
then
  log "ERROR" "sudo mkdir -p /mnt/myroot/home failed"
  exit ${rCode}
fi
echo 'done'

echo -n 'Mount filesystems...'
sudo mount /dev/xvdf1 /mnt/myroot/var
rCode=${?}
if [ ${rCode} -gt 0 ]
then
  log "ERROR" "sudo mount /dev/xvdf1 /mnt/myroot/var failed"
  exit ${rCode}
fi

sudo mount /dev/xvdg1 /mnt/myroot/var-tmp
rCode=${?}
if [ ${rCode} -gt 0 ]
then
  log "ERROR" "sudo mount /dev/xvdg1 /mnt/myroot/var-tmp failed"
  exit ${rCode}
fi

sudo mount /dev/xvdh1 /mnt/myroot/var-log
rCode=${?}
if [ ${rCode} -gt 0 ]
then
  log "ERROR" "sudo mount /dev/xvdh1 /mnt/myroot/var-log failed"
  exit ${rCode}
fi

sudo mount /dev/xvdi1 /mnt/myroot/var-log-audit
rCode=${?}
if [ ${rCode} -gt 0 ]
then
  log "ERROR" "sudo mount /dev/xvdi1 /mnt/myroot/var-log-audit failed"
  exit ${rCode}
fi

sudo mount /dev/xvdj1 /mnt/myroot/home
rCode=${?}
if [ ${rCode} -gt 0 ]
then
  log "ERROR" "sudo mount /dev/xvdj1 /mnt/myroot/home failed"
  exit ${rCode}
fi

echo 'done'

echo -n 'Rsyncing data from build image to target EBS volumes...'
sudo rsync -aHAX --exclude /var/tmp --exclude /var/log --exclude /var/log/audit /var/ /mnt/myroot/var
rCode=${?}
if [ ${rCode} -gt 0 ] && [ ${rCode} -ne 24 ]
then
  log "ERROR" "sudo rsync -aHAX --exclude /var/tmp --exclude /var/log --exclude /var/log/audit /var/ /mnt/myroot/var failed"
  exit ${rCode}
fi

sudo rsync -aHAX /var/tmp/ /mnt/myroot/var-tmp
rCode=${?}
if [ ${rCode} -gt 0 ] && [ ${rCode} -ne 24 ]
then
  log "ERROR" "sudo rsync -aHAX /var/tmp/ /mnt/myroot/var-tmp failed"
  exit ${rCode}
fi

sudo rsync -aHAX --exclude /var/log/audit /var/log/ /mnt/myroot/var-log
rCode=${?}
if [ ${rCode} -gt 0 ] && [ ${rCode} -ne 24 ]
then
  log "ERROR" "sudo rsync -aHAX --exclude /var/log/audit /var/log/ /mnt/myroot/var-log failed"
  exit ${rCode}
fi

sudo rsync -aHAX /var/log/audit/ /mnt/myroot/var-log-audit  
rCode=${?}
if [ ${rCode} -gt 0 ] && [ ${rCode} -ne 24 ]
then
  log "ERROR" "sudo rsync -aHAX /var/log/audit/ /mnt/myroot/var-log-audit failed"
  exit ${rCode}
fi

sudo rsync -aHAX /home/ /mnt/myroot/home
rCode=${?}
if [ ${rCode} -gt 0 ] && [ ${rCode} -ne 24 ]
then
  log "ERROR" "sudo rsync -aHAX /home/ /mnt/myroot/home failed"
  exit ${rCode}
fi

echo 'done'

echo 'Writing new /var partition to fstab...'
echo -e "$(sudo /usr/sbin/blkid /dev/xvdf1 | sed s/\"//g | cut -d' ' -f2)\t/var\t\txfs\tdefaults,nodev,nosuid\t0 2" | sudo tee -a /etc/fstab
rCode=${?}
if [ ${rCode} -gt 0 ]
then
  log "ERROR" "sudo tee -a /etc/fstab failed (/dev/xvdf1)"
  exit ${rCode}
fi

echo 'Writing new /var/tmp partition to fstab...'
echo -e "$(sudo /usr/sbin/blkid /dev/xvdg1 | sed s/\"//g | cut -d' ' -f2)\t/var/tmp\txfs\tdefaults,nodev,noexec,nosuid\t0 0" | sudo tee -a /etc/fstab
rCode=${?}
if [ ${rCode} -gt 0 ]
then
  log "ERROR" "sudo tee -a /etc/fstab failed (/dev/xvdg1)"
  exit ${rCode}
fi

echo 'Writing new /var/log partition to fstab...'
echo -e "$(sudo /usr/sbin/blkid /dev/xvdh1 | sed s/\"//g | cut -d' ' -f2)\t/var/log\txfs\tdefaults,nodev,nosuid\t0 2" | sudo tee -a /etc/fstab
rCode=${?}
if [ ${rCode} -gt 0 ]
then
  log "ERROR" "sudo tee -a /etc/fstab failed (/dev/xvdh1)"
  exit ${rCode}
fi

echo 'Writing new /var/log/audit partition to fstab...'
echo -e "$(sudo /usr/sbin/blkid /dev/xvdi1 | sed s/\"//g | cut -d' ' -f2)\t/var/log/audit\txfs\tdefaults,nodev,nosuid\t0 2" | sudo tee -a /etc/fstab
rCode=${?}
if [ ${rCode} -gt 0 ]
then
  log "ERROR" "sudo tee -a /etc/fstab failed (/dev/xvdi1)"
  exit ${rCode}
fi

echo 'Writing new /home partition to fstab...'
echo -e "$(sudo /usr/sbin/blkid /dev/xvdj1 | sed s/\"//g | cut -d' ' -f2)\t/home\t\txfs\tdefaults,nodev,nosuid\t0 2" | sudo tee -a /etc/fstab
rCode=${?}
if [ ${rCode} -gt 0 ]
then
  log "ERROR" "sudo tee -a /etc/fstab failed (/dev/xvdj1)"
  exit ${rCode}
fi

echo 'Writing new /tmp partition to fstab...'
echo -e "tmpfs\t\t\t\t\t\t/tmp\t\ttmpfs\tdefaults,noatime,nodev,noexec,nosuid,size=256m  0 0" | sudo tee -a /etc/fstab
rCode=${?}
if [ ${rCode} -gt 0 ]
then
  log "ERROR" "sudo tee -a /etc/fstab failed (/dev/xvdk1)"
  exit ${rCode}
fi

echo 'Adding explicit /dev/shm content to fstab...'
echo -e "tmpfs\t\t\t\t\t\t/dev/shm\t\ttmpfs\tdefaults,nodev,nosuid,noexec  0 0" | sudo tee -a /etc/fstab
rCode=${?}
if [ ${rCode} -gt 0 ]
then
  log "ERROR" "sudo tee -a /etc/fstab failed (/dev/xvdk1)"
  exit ${rCode}
fi

sync && sleep 1
echo
echo -n "Unmounting copy mounts..."
for i in var var-log var-log-audit var-tmp home
do 
  sudo umount /mnt/myroot/${i}
  rCode=${?}
  if [ ${rCode} -gt 0 ]
  then
    log "ERROR" "sudo umount /mnt/myroot/${i} failed"
    exit ${rCode}
  fi
done

## clean mount points and remount filesystems
#
echo
##################################################################################################
echo "${C}"
echo "## Finalise mounts"
echo "#"
sudo rm -rf /var/tmp/* >/dev/null 2>&1
## dracut leaves initramfs refs in /var/tmp which cause issues with rm so let's do best endeavours
# rCode=${?}
# if [ ${rCode} -gt 0 ]
# then
#   log "ERROR" "sudo rm -rf /var/tmp/* failed"
#   exit ${rCode}
# fi

sudo rm -rf /var/log/*
rCode=${?}
if [ ${rCode} -gt 0 ]
then
  log "ERROR" "sudo rm -rf /var/log/* failed"
  exit ${rCode}
fi

sudo rm -rf /var/log/audit*
rCode=${?}
if [ ${rCode} -gt 0 ]
then
  log "ERROR" "sudo rm -rf /var/log/audit* failed"
  exit ${rCode}
fi

sudo rm -rf /home/*
rCode=${?}
if [ ${rCode} -gt 0 ]
then
  log "ERROR" "sudo rm -rf /home/* failed"
  exit ${rCode}
fi

sudo rm -rf /mnt/*
rCode=${?}
if [ ${rCode} -gt 0 ]
then
  log "ERROR" "sudo rm -rf /mnt/* failed"
  exit ${rCode}
fi

sudo umount /var/lib/nfs/rpc_pipefs
rCode=${?}
if [ ${rCode} -gt 0 ]
then
  log "ERROR" "sudo umount /var/lib/nfs/rpc_pipefs failed"
  exit ${rCode}
fi

sudo find -H /var -ignore_readdir_race -xautofs -mount -not -path "/var/tmp" -not -path "/var" -delete
rCode=${?}
if [ ${rCode} -gt 0 ]
then
  log "ERROR" "sudo find -H /var -ignore_readdir_race -xautofs -mount -not -path '/var/tmp' -not -path '/var' -delete failed"
  exit ${rCode}
fi

sudo mount -a         # remount the above prepared partitions and continue
rCode=${?}
if [ ${rCode} -gt 0 ]
then
  log "ERROR" "sudo mount -a failed"
  exit ${rCode}
fi
echo

##################################################################################################
echo "${C}"
echo "## CIS benchmarking: Remove unneeded filesystems"
echo "#"
## Confer compliance for CIS_CentOS_Linux_7_Benchmarking_v2.2.0.
#
CISCONFIG=/etc/modprobe.d/CIS.conf
for fs in cramfs freevxfs jffs2 hfs hfsplus squashfs udf vfat 
do
  echo "install ${fs} /bin/true" | sudo tee -a ${CISCONFIG}
  THISMOD=$(lsmod | grep ${fs})
  if [[ -n "${THISMOD}" ]]
  then
    echo "Removing FS ${fs}"
    sudo rmmod ${fs}
    rCode=${?}
    if [ ${rCode} -gt 0 ]
    then
      log "ERROR" "sudo rmmod ${fs} failed"
      exit ${rCode}
    fi
  fi
done

##################################################################################################
echo ${C}
echo "## Upgrade the kernel"
echo "#"
echo "## rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org"
echo "#"
sudo rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
rCode=${?}
if [ ${rCode} -gt 0 ]
then
  log "ERROR" "sudo rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org failed"
  exit ${rCode}
fi
echo 'done'
echo

##################################################################################################
echo ${C}
echo "## yum -y install https://www.elrepo.org/elrepo-release-7.0-4.el7.elrepo.noarch.rpm"
echo "#"
sudo yum -y install https://www.elrepo.org/elrepo-release-7.0-4.el7.elrepo.noarch.rpm
rCode=${?}
if [ ${rCode} -gt 0 ]
then
  log "ERROR" "sudo yum -y install https://www.elrepo.org/elrepo-release-7.0-4.el7.elrepo.noarch.rpm failed"
  exit ${rCode}
fi
echo 'done'
echo

##################################################################################################
echo ${C}
echo "## blacklist wireless drivers and usbstorage"
echo "#"
echo 'blacklist usb-storage' | sudo tee -a /tmp/e
rCode=${?}
if [ ${rCode} -gt 0 ]
then
  log "ERROR" "echo 'blacklist usb-storage' | sudo tee -a /tmp/e failed"
  exit ${rCode}
fi

sudo mv -f /tmp/e /etc/modprobe.d/blacklist-usbstorage
rCode=${?}
if [ ${rCode} -gt 0 ]
then
  log "ERROR" "sudo mv -f /tmp/e /etc/modprobe.d/blacklist-usbstorage failed"
  exit ${rCode}
fi

#sudo find /lib/modules/$(rpm -q kernel-ml | sed 's/kernel-ml-//')/kernel/drivers/net/wireless -name \*.ko -type f >> /tmp/f
sudo find /lib/modules/"$(uname -r)"/kernel/drivers/net/wireless -name \*.ko -type f | sudo tee -a /tmp/f
rCode=${?}
if [ ${rCode} -gt 0 ]
then
  log "ERROR" "sudo find /lib/modules/'$(uname -r)'/kernel/drivers/net/wireless -name \*.ko -type f | sudo tee -a /tmp/f failed"
  exit ${rCode}
fi

sudo sed -i 's/^/blacklist /' /tmp/f
rCode=${?}
if [ ${rCode} -gt 0 ]
then
  log "ERROR" "sudo sed -i 's/^/blacklist /' /tmp/f failed"
  exit ${rCode}
fi

sudo mv -f /tmp/f /etc/modprobe.d/blacklist-wireless
rCode=${?}
if [ ${rCode} -gt 0 ]
then
  log "ERROR" "sudo mv -f /tmp/f /etc/modprobe.d/blacklist-wireless failed"
  exit ${rCode}
fi

sudo rm -f /tmp/e /tmp/f
rCode=${?}
if [ ${rCode} -gt 0 ]
then
  log "ERROR" "sudo rm -f /tmp/e /tmp/f failed"
  exit ${rCode}
fi
echo 'done'
echo

##################################################################################################
echo ${C}
echo "## install telnet, unzip so we can download hashicorp apps"
echo "#"
sudo yum -y install unzip telnet
rCode=${?}
if [ ${rCode} -gt 0 ]
then
  log "ERROR" "sudo yum -y install unzip telnet failed"
  exit ${rCode}
fi

sudo curl -Lo /usr/bin/jq https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
rCode=${?}
if [ ${rCode} -gt 0 ]
then
  log "ERROR" "sudo curl -Lo /usr/bin/jq https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 failed"
  exit ${rCode}
fi

sudo chmod +x /usr/bin/jq
rCode=${?}
if [ ${rCode} -gt 0 ]
then
  log "ERROR" "sudo chmod +x /usr/bin/jq failed"
  exit ${rCode}
fi

sudo yum clean metadata
rCode=${?}
if [ ${rCode} -gt 0 ]
then
  log "ERROR" "sudo yum clean metadata failed"
  exit ${rCode}
fi

sudo yum -y install epel-release
rCode=${?}
if [ ${rCode} -gt 0 ]
then
  log "ERROR" "sudo yum -y install epel-release failed"
  exit ${rCode}
fi
echo

##################################################################################################
echo ${C}
echo "## setup time daemon"
echo "#"
sudo yum -y install ntp
rCode=${?}
if [ ${rCode} -gt 0 ]
then
  log "ERROR" "sudo yum -y install ntp failed"
  exit ${rCode}
fi

sudo systemctl enable ntpd
rCode=${?}
if [ ${rCode} -gt 0 ]
then
  log "ERROR" "sudo systemctl enable ntpd failed"
  exit ${rCode}
fi

sudo systemctl start ntpd
rCode=${?}
if [ ${rCode} -gt 0 ]
then
  log "ERROR" "sudo systemctl start ntpd failed"
  exit ${rCode}
fi
echo

##################################################################################################
echo ${C}
echo "## setup selinux"
echo "#"
sudo yum -y install setools-console setroubleshoot-server
rCode=${?}
if [ ${rCode} -gt 0 ]
then
  log "ERROR" "sudo yum -y install setools-console setroubleshoot-server failed"
  exit ${rCode}
fi

sudo sed -i 's/^SELINUX=.*$/SELINUX=enforcing/' /etc/selinux/config
rCode=${?}
if [ ${rCode} -gt 0 ]
then
  log "ERROR" "sudo sed -i 's/^SELINUX=.*$/SELINUX=enforcing/' /etc/selinux/config failed"
  exit ${rCode}
fi

sudo sed -i 's/^SELINUXTYPE=.*$/SELINUXTYPE=targeted/' /etc/selinux/config
rCode=${?}
if [ ${rCode} -gt 0 ]
then
  log "ERROR" "sudo sed -i 's/^SELINUXTYPE=.*$/SELINUXTYPE=targeted/' /etc/selinux/config failed"
  exit ${rCode}
fi

##################################################################################################
echo ${C}
echo "## setup firewalld, change default ssh port, disabled unneeded"
echo "#"
sudo yum -y install firewalld
rCode=${?}
if [ ${rCode} -gt 0 ]
then
  log "ERROR" "sudo yum -y install firewalld failed"
  exit ${rCode}
fi

sudo systemctl enable firewalld
rCode=${?}
if [ ${rCode} -gt 0 ]
then
  log "ERROR" "sudo systemctl enable firewalld failed"
  exit ${rCode}
fi

sudo systemctl start firewalld
rCode=${?}
if [ ${rCode} -gt 0 ]
then
  log "ERROR" "sudo systemctl start firewalld failed"
  exit ${rCode}
fi

# sudo firewall-cmd --permanent --add-port=65444/tcp
sudo firewall-cmd --permanent --add-port=22/tcp
rCode=${?}
if [ ${rCode} -gt 0 ]
then
  log "ERROR" "sudo firewall-cmd --permanent --add-port=22/tcp failed"
  exit ${rCode}
fi
# sudo sed -i 's/^#Port 22/Port 65444/' /etc/ssh/sshd_config
# sudo semanage port -a -t ssh_port_t -p tcp 65444
# looks like phoenix fails if ssh not on 22, so leaving these two to phoenixWhizz
#
# also remember the vpc sgs to update also
sudo firewall-cmd --reload
rCode=${?}
if [ ${rCode} -gt 0 ]
then
  log "ERROR" "sudo firewall-cmd --reload failed"
  exit ${rCode}
fi

echo

##################################################################################################
echo ${C}
echo "## lock up root home dir"
echo "#"
sudo chmod 700 /root
rCode=${?}
if [ ${rCode} -gt 0 ]
then
  log "ERROR" "sudo chmod 700 /root failed"
  exit ${rCode}
fi

echo 'done'
echo

##################################################################################################
echo ${C}
echo "## change default umask"
echo "#"
sudo sed -i 's/umask 0../umask 077/g' /etc/bashrc
rCode=${?}
if [ ${rCode} -gt 0 ]
then
  log "ERROR" "sudo sed -i 's/umask 0../umask 077/g' /etc/bashrc failed"
  exit ${rCode}
fi

sudo sed -i 's/umask 0../umask 077/g' /etc/csh.cshrc
rCode=${?}
if [ ${rCode} -gt 0 ]
then
  log "ERROR" "sudo sed -i 's/umask 0../umask 077/g' /etc/csh.cshrc failed"
  exit ${rCode}
fi

echo 'done'
echo

##################################################################################################
echo ${C}
echo "## touch output log for pam_tally2"
echo "#"
sudo touch /var/log/tallylog
rCode=${?}
if [ ${rCode} -gt 0 ]
then
  log "ERROR" "sudo touch /var/log/tallylog failed"
  exit ${rCode}
fi

echo 'done'
echo

##################################################################################################
echo ${C}
echo "## set ifcfg-eth0 to ONBOOT true"
echo "#"
sudo sed -i -e 's@^ONBOOT="no@ONBOOT="yes@' /etc/sysconfig/network-scripts/ifcfg-eth0
rCode=${?}
if [ ${rCode} -gt 0 ]
then
  log "ERROR" "sudo sed -i -e 's@^ONBOOT="no@ONBOOT="yes@' /etc/sysconfig/network-scripts/ifcfg-eth0 failed"
  exit ${rCode}
fi

echo 'done'
echo

##################################################################################################
echo ${C}
echo "## rm unnecessary rpms (rm mariadb-libs = rm postfix)"
echo "#"
sudo yum remove -y chrony kexec-tools polkit irqbalance "$(rpm -qa iwl\*)" kbd* krb-devel less libteam mariadb-libs microcode_ctl parted rsync
rCode=${?}
if [ ${rCode} -gt 0 ]
then
  log "ERROR" "sudo yum remove -y chrony etc failed"
  exit ${rCode}
fi

sudo yum remove -y tuned wpa_supplicant rsyslog portmap nfs-utils
rCode=${?}
if [ ${rCode} -gt 0 ]
then
  log "ERROR" "sudo yum remove -y tuned etc failed"
  exit ${rCode}
fi
echo

##################################################################################################
echo ${C}
echo "## set vi bindings in case of login to root and centos user (broken CI/CD pipeline?)"
echo "#"
echo "set -o vi" | sudo tee -a /root/.bashrc
rCode=${?}
if [ ${rCode} -gt 0 ]
then
  log "ERROR" "sudo tee -a /root/.bashrc failed"
  exit ${rCode}
fi

echo "set -o vi" | sudo tee -a ~centos/.bashrc
rCode=${?}
if [ ${rCode} -gt 0 ]
then
  log "ERROR" "sudo tee -a ~centos/.bashrc failed"
  exit ${rCode}
fi

echo

##################################################################################################
## yum update done here so we do not waste time updating kit we then remove.
## the yum update may install a new non-kernel-ml, so grub update is after this but before we 
## harden the kernel in case of introduction of specific tweaks supported on only certain versions
#
echo ${C}
echo "## cleaning yum database"
echo "#"
sudo yum -y update
rCode=${?}
if [ ${rCode} -gt 0 ]
then
  log "ERROR" "sudo yum -y update failed"
  exit ${rCode}
fi

sudo yum -y clean all
rCode=${?}
if [ ${rCode} -gt 0 ]
then
  log "ERROR" "sudo yum -y clean all failed"
  exit ${rCode}
fi

sudo rm -rf /var/cache/yum
rCode=${?}
if [ ${rCode} -gt 0 ]
then
  log "ERROR" "sudo rm -rf /var/cache/yum failed"
  exit ${rCode}
fi
echo

##################################################################################################
## mainline the kernel
#
echo ${C}
echo "## yum-config-manager --enable elrepo-kernel"
echo "#"
sudo yum-config-manager --enable elrepo-kernel
rCode=${?}
if [ ${rCode} -gt 0 ]
then
  log "ERROR" "sudo yum-config-manager --enable elrepo-kernel failed"
  exit ${rCode}
fi
echo

##################################################################################################
## mainline the kernel
#
echo ${C}
echo "## yum -y install kernel-ml"
echo "#"
sudo yum -y install kernel-ml
rCode=${?}
if [ ${rCode} -gt 0 ]
then
  log "ERROR" "sudo yum -y install kernel-ml failed"
  exit ${rCode}
fi
echo

##################################################################################################
## mainline the kernel
#
echo ${C}
echo "## sed -i 's/GRUB_DEFAULT.*/GRUB_DEFAULT=0/' /etc/default/grub"
echo "#"
sudo sed -i 's/GRUB_DEFAULT.*/GRUB_DEFAULT=0/' /etc/default/grub
rCode=${?}
if [ ${rCode} -gt 0 ]
then
  log "ERROR" "sudo sed -i 's/GRUB_DEFAULT.*/GRUB_DEFAULT=0/' /etc/default/grub failed"
  exit ${rCode}
fi

sudo sed -i 's/\(GRUB_CMDLINE_LINUX=.*\)\"$/\1 biosdevname=0 net.ifnames=0 ipv6.disable=1\"/' /etc/default/grub
rCode=${?}
if [ ${rCode} -gt 0 ]
then
  log "ERROR" "sudo sed -i 's/\(GRUB_CMDLINE_LINUX=.*\)\"$/\1 biosdevname=0 net.ifnames=0 ipv6.disable=1\"/' /etc/default/grub failed"
  exit ${rCode}
fi
echo 'done'
echo

##################################################################################################
## mainline the kernel
#
echo ${C}
echo "## grub2-mkconfig -o /boot/grub2/grub.cfg"
echo "#"
sudo grub2-mkconfig -o /boot/grub2/grub.cfg
rCode=${?}
if [ ${rCode} -gt 0 ]
then
  log "ERROR" "sudo grub2-mkconfig -o /boot/grub2/grub.cfg failed"
  exit ${rCode}
fi
echo

##################################################################################################
echo ${C}
echo "## harden the kernel"
echo "#"
## kernel tweaks from https://www.cyberciti.biz/faq/linux-kernel-etcsysctl-conf-security-hardening/ and others like
## http://drupal.bitfunnel.net/drupal/centos-7.4.1708-x86_64-minimal-install
## NOTE not all tweaks from above address are merited eg. net.ipv4.tcp_synack_retries
#                           #
#    #  ####  ##### ###### ###
##   # #    #   #   #       #
# #  # #    #   #   #####
#  # # #    #   #   #       #
#   ## #    #   #   #      ###
#    #  ####    #   ######  #
#
## NOTE: you need bash -c for sysctl.conf writes unless you wanna write them into another file and mv
## start with https://javapipe.com/ddos/blog/iptables-ddos-protection/ researched each, not accepting all...
#
cat << EOF > /tmp/sysctl.conf-additions
#
## ADDITIONS
#
## Controls whether core dumps will append the PID to the core filename
## Useful for debugging multi-threaded applications
## - Also, already 1 in aws Redhat AMIs but check https://tobyheywood.com/linux-kernel-tweaks-kernel-core_uses_pid/
#
kernel.core_uses_pid = 1
#
## Controls the System Request debugging functionality of the kernel
## https://www.kernel.org/doc/html/latest/admin-guide/sysrq.html
#
kernel.sysrq = 0
#
## Enable ASLR for stack pointer, shm, address space and data segment locations
## https://linux-audit.com/linux-aslr-and-kernelrandomize_va_space-setting/
## https://www.cyberciti.biz/faq/linux-kernel-etcsysctl-conf-security-hardening/
#
kernel.randomize_va_space = 2
#
## increase system file descriptor, pid and IP port port limit
## https://www.cyberciti.biz/faq/linux-increase-the-maximum-number-of-open-files/
#
fs.file-max = 2097152
kernel.pid_max = 65536

### https://unix.stackexchange.com/questions/13019/description-of-kernel-printk-values
#
kernel.printk = 4 4 1 7
#
## https://unix.stackexchange.com/questions/29567/configure-reboot-on-linux-kernel-panic#29569
#
kernel.panic = 10
#
## https://blog.pythian.com/the-mysterious-world-of-shmmax-and-shmall/
#
kernel.shmmax = 4294967296
#
## https://www.linuxquestions.org/questions/linux-newbie-8/meaning-of-shmall-kernel-variable-607991/
#
kernel.shmall = 4194304
#
## https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/6/html/performance_tuning_guide/s-memory-tunables
#
vm.swappiness = 20
#
## https://lonesysadmin.net/2013/12/22/better-linux-disk-caching-performance-vm-dirty_ratio/
#
vm.dirty_ratio = 80
vm.dirty_background_ratio = 5
#
## https://wiki.mikejung.biz/Sysctl_tweaks
#
net.core.netdev_max_backlog = 262144
#
## https://github.com/docker-library/redis/issues/35
#
net.core.somaxconn = 65535
#
## https://www.vultr.com/docs/securing-and-hardening-the-centos-7-kernel-with-sysctl and others
#
net.core.optmem_max = 25165824
#
########################## IPV4 ##########################
#
## Controls IP packet forwarding
#
net.ipv4.ip_forward = 0
#
## send redirects, if router, but this is just server
#
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
#
## Accept packets with SRR option? No
#
net.ipv4.conf.all.accept_source_route = 0
#
## Do not accept source routing
#
net.ipv4.conf.default.accept_source_route = 0

## Accept Redirects? No, this is not router
#
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
#
## Log packets with impossible addresses to kernel log? yes
## https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/tree/Documentation/networking/ip-sysctl.txt?id=bb077d600689dbf9305758efed1e16775db1c84c#n843
#
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
#
## Ignore all ICMP ECHO and TIMESTAMP requests sent to it via broadcast/multicast; Ensure bogus ICMP responses are ignored
#
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
#
## Prevent against the common 'syn flood attack'
#
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 16384
#
## controls source route verification
## https://www.slashroot.in/linux-kernel-rpfilter-settings-reverse-path-filtering
#
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
## https://www.cyberciti.biz/faq/centos-redhat-debian-linux-neighbor-table-overflow/
#
net.ipv4.neigh.default.gc_thresh1 = 4096
net.ipv4.neigh.default.gc_thresh2 = 8192
net.ipv4.neigh.default.gc_thresh3 = 16384
#
## https://stackoverflow.com/questions/15372011/configuring-arp-age-timeout
#
net.ipv4.neigh.default.gc_interval = 5
#
## https://stackoverflow.com/questions/15372011/configuring-arp-age-timeout
#
net.ipv4.neigh.default.gc_stale_time = 120
#
## http://www.lognormal.com/blog/2012/09/27/linux-tcpip-tuning/ &
## https://www.cdnplanet.com/blog/tune-tcp-initcwnd-for-optimum-performance/
#
net.ipv4.tcp_slow_start_after_idle = 0
#
## https://www.cyberciti.biz/tips/linux-increase-outgoing-network-sockets-range.html
#
net.ipv4.ip_local_port_range = 10241 65500
#
## https://www.frozentux.net/ipsysctl-tutorial/chunkyhtml/variablereference.html
## https://duckduckgo.com/?q=sysctl+net.ipv4.ip_no_pmtu_disc&t=ffab&ia=web all seem to point to no path mtu discovery
#
net.ipv4.ip_no_pmtu_disc = 1
#
## https://easyengine.io/tutorials/linux/sysctl-conf/
#
net.ipv4.udp_rmem_min = 16384
net.ipv4.udp_wmem_min = 16384
#
## https://www.cyberciti.biz/files/linux-kernel/Documentation/networking/ip-sysctl.txt && taken from javapipe and others
#
net.ipv4.tcp_mem = 65536 131072 262144
net.ipv4.udp_mem = 65536 131072 262144
#
## default aws net.ipv4.tcp_rmem = 4096	87380	6291456
## https://www.cyberciti.biz/files/linux-kernel/Documentation/networking/ip-sysctl.txt
#
net.ipv4.tcp_rmem = 4096 87380 33554432
#
## default aws net.ipv4.tcp_wmem = 4096	16384	4194304
#
net.ipv4.tcp_wmem = 4096 87380 33554432
#
## https://easyengine.io/tutorials/linux/sysctl-conf/ and the docs
#
net.ipv4.tcp_max_tw_buckets = 1440000
#
## https://vincent.bernat.im/en/blog/2014-tcp-time-wait-state-linux#netipv4tcp_tw_reuse
#
net.ipv4.tcp_tw_reuse = 1
#
## http://cs.baylor.edu/~donahoo/tools/hacknet/TIME-WAIT.html
#
net.ipv4.tcp_fin_timeout = 30
#
## http://www.tldp.org/HOWTO/TCP-Keepalive-HOWTO/usingkeepalive.html
#
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_keepalive_intvl = 60
net.ipv4.tcp_keepalive_probes = 10
#
## https://www.nas.nasa.gov/hecc/support/kb/Optional-Advanced-Tuning-for-Linux_138.html
#
net.ipv4.tcp_no_metrics_save = 1
#
######################## END IPV4 ##########################
########################## IPV6 ##########################
## Number of Router Solicitations to send until assuming no routers are present.
## This is host and not router
#
net.ipv6.conf.default.router_solicitations = 0
#
## Accept Router Preference in RA?
#
net.ipv6.conf.default.accept_ra_rtr_pref = 0
#
## Learn Prefix Information in Router Advertisement
#
net.ipv6.conf.default.accept_ra_pinfo = 0
#
## Setting controls whether the system will accept Hop Limit settings from a router advertisement
#
net.ipv6.conf.default.accept_ra_defrtr = 0
#
## router advertisements can cause the system to assign a global unicast address to an interface
#
net.ipv6.conf.default.autoconf = 0
#
## how many neighbor solicitations to send out per address?
#
net.ipv6.conf.default.dad_transmits = 0
#
## How many global unicast IPv6 addresses can be assigned to each interface?
#
net.ipv6.conf.default.max_addresses = 1
#
######################## END IPV6 ##########################
EOF
rCode=${?}
if [ ${rCode} -gt 0 ]
then
  log "ERROR" "Writing kernel tuning parameters to /tmp failed"
  exit ${rCode}
fi

sudo cat /tmp/sysctl.conf-additions | sudo tee -a /etc/sysctl.conf
rCode=${?}
if [ ${rCode} -gt 0 ]
then
  log "ERROR" "sudo cat /tmp/sysctl.conf-additions | sudo tee -a /etc/sysctl.conf failed"
  exit ${rCode}
fi
#
## reload changes to catch panics
#
sudo sysctl -p
rCode=${?}
if [ ${rCode} -gt 0 ]
then
  log "ERROR" "sudo sysctl -p failed"
  exit ${rCode}
fi

echo
echo 'done with kernel tweaks'
echo

##################################################################################################
echo ${C}
echo "## general tidy up"
echo "#"
sudo rm -rf /etc/tuned /etc/chrony* /root/anaconda-ks.cfg /root/original-ks.cfg /var/log/wpa_supplicant.log /var/log/anaconda /var/log/ppp /var/log/tuned /var/log/firewalld
rCode=${?}
if [ ${rCode} -gt 0 ]
then
  log "ERROR" "sudo rm -rf /etc/tuned... failed"
  exit ${rCode}
fi

sudo rm -rf /tmp/*
rCode=${?}
if [ ${rCode} -gt 0 ]
then
  log "ERROR" "sudo rm -rf /tmp/* failed"
  exit ${rCode}
fi

cat /dev/null > ~/.bash_history
rCode=${?}
if [ ${rCode} -gt 0 ]
then
  log "ERROR" "cat /dev/null > ~/.bash_history failed"
  exit ${rCode}
fi

history -c
rCode=${?}
if [ ${rCode} -gt 0 ]
then
  log "ERROR" "history -c failed"
  exit ${rCode}
fi

echo 'done with tidying up'
echo

##################################################################################################
echo "${C}"
echo "## CIS benchmarking: Install/configure AIDE"
echo "#"
sudo yum -y install aide
rCode=${?}
if [ ${rCode} -gt 0 ]
then
  log "ERROR" "sudo yum -y install aide failed"
  exit ${rCode}
fi

sudo aide --init
rCode=${?}
if [ ${rCode} -gt 0 ]
then
  log "ERROR" "sudo aide --init failed"
  exit ${rCode}
fi

sudo mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz
rCode=${?}
if [ ${rCode} -gt 0 ]
then
  log "ERROR" "sudo mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz failed"
  exit ${rCode}
fi

## should be no crontab on new machine, so overwrite root crontab with single command
#
echo "0 5 * * * /usr/sbin/aide --check" | sudo crontab -
rCode=${?}
if [ ${rCode} -gt 0 ]
then
  log "ERROR" "(sudo crontab -l || true; echo '0 5 * * * /usr/sbin/aide --check') | sudo crontab - failed"
  exit ${rCode}
fi

##################################################################################################
echo ${C}
echo "Base system written."
echo ${C}

echo 'done'
exit 0
#
## jah brendan
