#!/bin/bash
export PATH=/sbin:/bin:/usr/sbin:/usr/bin
export meego_dest=/var/yum/meego/update/1.2.0/repos
export meego_mirror_site=rsync://mirrors.kernel.org/mirrors/meego/updates/1.2.0/repos
export rsync_log_path=/var/log/rsync
i=1
count=10

function send_mail() {
  grep \.rpm$ /tmp/meego_updatelist.log | awk -F/ '{print $NF}' | sort -u -V > meego_updatelist.txt
  if [ -s "meego_updatelist.txt" ]; then
    cat update.mail | mail -s "Update list" -a meego_updatelist.txt perngs@gmail.com
  else
    cat noupdate.mail | mail -s "Update list" perngs@gmail.com
  fi
}


if [ -z "$1" ]; then
  echo "Usage: rsync.sh filelist"
  exit 1
elif [ ! -e "$1" ]; then
  echo "$1 is not exist"
  exit 2
fi

while [ "$i" -le "$count" ]
do
  rsync -rptgoLDv --timeout=120 --include-from=$1 --log-file=$rsync_log_path/rsync_`date +%Y%m%d`.log --progress $meego_mirror_site/ \
$meego_dest | tee -a /tmp/meego_updatelist.log >> $rsync_log_path/meego_updatelist_`date +%Y%m%d`
  if [ "$?" == "0" ]; then
    echo "download successful"
    break
  else
    echo "download failed,retry $i"
    sleep 10
    i=$(($i+1))
  fi
done

send_mail;
