#!/bin/bash
export PATH=/sbin:/bin:/usr/sbin:/usr/bin
export sl_dest=/var/yum/scientific/6.2
export sl_mirror_site=rsync://ftp.riken.jp/scientificlinux/6.2
export rsync_log_path=/var/log/rsync
i=1
count=10

function send_mail() {
  grep src.rpm$ $rsync_log_path/sl_updatelist_`date +%Y%m%d` | sort -u -V > sl_list.txt
  if [ -s "sl_updatelist.txt" ]; then
    grep \.rpm$ $rsync_log_path/sl_updatelist_`date +%Y%m%d` | awk -F/ '{print $NF}' | sort -u -V > /tmp/sl_updatelist.txt
    cat update.mail | mail -s "Update list" -a /tmp/sl_updatelist.txt perngs@gmail.com
    rm /tmp/sl_updatelist.log
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

for arch in i386 x86_64 SRPMS
do
  while [ "$i" -le "$count" ]
  do
    rsync -rptgoLDv --timeout=120 --include-from=$1 --log-file=$rsync_log_path/rsync_`date +%Y%m%d`.log --progress \
$sl_mirror_site/$arch $sl_dest > $rsync_log_path/sl_updatelist_`date +%Y%m%d`
      if [ "$?" == "0" ]; then
        echo "$arch download successful"
        break
      else
        echo "$arch download failed,retry $i"
        sleep 10
        i=$(($i+1))
      fi
  done
done

send_mail;
