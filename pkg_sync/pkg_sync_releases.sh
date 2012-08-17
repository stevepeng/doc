#!/bin/bash
export PATH=/sbin:/bin:/usr/sbin:/usr/bin
user=git
git_ip=127.0.0.1
rsync_log_path=/var/log/rsync
pkg_sync_dir=$(pwd)
sl_pkgs_path=/var/yum/scientific/6.2
fc_pkgs_path=/var/yum/fedora/releases/17/Everything
meego_pkgs_path=/var/yum/meego/releases/1.2.0
sl_mirror_site=rsync://ftp.riken.jp/scientificlinux/6.2
fc_mirror_site=rsync://mirror.nexicom.net/Fedora/releases/17/Everything
fc_arm_mirror_site=rsync://archive.eu.kernel.org/fedora-secondary/releases/17/Everything
meego_mirror_site=rsync://mirrors.kernel.org/mirrors/meego/releases/1.2.0
sl_git_path=/var/git/packages/scientific/6.2
fc_git_path=/var/git/packages/fedora/17/Everything
meego_git_path=/var/git/packages/meego/1.2.0
count=10

function sl_pkgs_download() {
  rm $rsync_log_path/sl_updatelist_$(date +%Y%m%d) 2> /dev/null
  if [ ! -e "$pkg_sync_dir/list/sl_git.list" ]; then
    echo "$pkg_sync_dir/list/sl_git.list not exist"
    logger -i -p local5.notice -t pkg_rsync "$pkg_sync_dir/list/sl_git.list not exist"
    exit 2
  fi
  i=1
  for arch in i386 x86_64
  do
    while [ "$i" -le "$count" ]
    do
      rsync -rptLDv --timeout=120 --include-from=$pkg_sync_dir/list/sl_pkgs.list --log-file=$rsync_log_path/sl_rsync_$(date +%Y%m%d).log \
--progress $sl_mirror_site/$arch/os/Packages $sl_pkgs_path/$arch/os >> $rsync_log_path/sl_updatelist_$(date +%Y%m%d)
        if [ "$?" == "0" ]; then
          echo "Download successfully(scientific linux,$arch)"
          break
        else
          echo "Download failed(scientific linux,$arch)"
          logger -i -p local5.notice -t pkg_rsync "Download failed(scientific linux,$arch)"
          sleep 10
          i=$(($i+1))
        fi
    done
  done
  grep src.rpm$ $rsync_log_path/sl_updatelist_$(date +%Y%m%d) | sort -t "/" -u -V -k 3 > $pkg_sync_dir/list/sl_git.list
}

function fc_pkgs_download() {
  rm $rsync_log_path/fc_updatelist_$(date +%Y%m%d) 2> /dev/null
  i=1
  for arch in i386 x86_64
  do
    while [ "$i" -le "$count" ]
    do
      rsync -rptLDv --timeout=120 --include-from=$pkg_sync_dir/list/fc_pkgs.list --log-file=$rsync_log_path/fc_rsync_$(date +%Y%m%d).log \
--progress $fc_mirror_site/$arch/os/Packages $fc_pkgs_path/$arch/os >> $rsync_log_path/fc_updatelist_$(date +%Y%m%d)
        if [ "$?" == "0" ]; then
          echo "Download successfully(Fedora,$arch)"
          break
        else
          echo "Download failed(Fedora,$arch)"
          logger -i -p local5.notice -t pkg_rsync "Download successfully(Fedora,$arch)"
          sleep 10
          i=$(($i+1))
        fi
    done
  done

  i=1
  for arch in arm armhfp
  do
    while [ "$i" -le "$count" ]
    do
      rsync -rptLDv --timeout=120 --include-from=$pkg_sync_dir/list/fc_pkgs.list --log-file=$rsync_log_path/fc_rsync_$(date +%Y%m%d).log \
--progress $fc_arm_mirror_site/$arch/os/Packages $fc_pkgs_path/$arch/os >> $rsync_log_path/fc_updatelist_$(date +%Y%m%d)
        if [ "$?" == "0" ]; then
          echo "Download successfully(Fedora,$arch)"
          break
        else
          echo "Download failed(Fedora,$arch)"
          logger -i -p local5.notice -t pkg_rsync "Download successfully(Fedora,$arch)"
          sleep 10
          i=$(($i+1))
        fi
    done
  done

  i=1
  while [ "$i" -le "$count" ]
  do
    rsync -rptLDv --timeout=120 --include-from=$pkg_sync_dir/list/fc_pkgs.list --log-file=$rsync_log_path/fc_rsync_$(date +%Y%m%d).log \
--progress $fc_mirror_site/source/SRPMS $fc_pkgs_path/source >> $rsync_log_path/fc_updatelist_$(date +%Y%m%d)
      if [ "$?" == "0" ]; then
        echo "Download successfully(Fedora,SRPMS)"
        break
      else
        echo "Download failed(Fedora,$arch)"
        logger -i -p local5.notice -t pkg_rsync "Download successfully(Fedora,SRPMS)"
        sleep 10
        i=$(($i+1))
      fi
  done
  grep src.rpm$ $rsync_log_path/fc_updatelist_$(date +%Y%m%d) | sort -u -V > $pkg_sync_dir/list/fc_git.list
}

function meego_pkgs_download() {
  i=1
  while [ "$i" -le "$count" ]
  do
    rsync -rptLDv --timeout=120 --include-from=$pkg_sync_dir/list/meego_pkgs.list --log-file=$rsync_log_path/meego_rsync_$(date +%Y%m%d).log \
--progress $meego_mirror_site/repos $meego_pkgs_path >> $rsync_log_path/meego_updatelist_$(date +%Y%m%d)
    if [ "$?" == "0" ]; then
      echo "Download successfully(meego)"
      break
    else
      echo "Download failed(meego)"
      logger -i -p local5.notice -t pkg_rsync "Download failed(meego)"
      sleep 10
      i=$(($i+1))
    fi
  done
  grep src.rpm$ $rsync_log_path/meego_updatelist_$(date +%Y%m%d) | sort -u -V > $pkg_sync_dir/list/meego_git.list
}

function send_mail() {
  echo "sl update list:" >> /tmp/update.list
  if [ -n "$(grep \.rpm$ $rsync_log_path/sl_updatelist_$(date +%Y%m%d))" ]; then
    grep \.rpm$ $rsync_log_path/sl_updatelist_$(date +%Y%m%d) | awk -F / '{print $NF}' | sort -u -V >> /tmp/update.list
    echo "scientific has updated" >> /tmp/update.mail
  else
    echo "scientific no update" >> /tmp/update.list
    echo "scientific no update" >> /tmp/update.mail
  fi

  echo "Fedora update list:" >> /tmp/update.list
  if [ -n "$(grep \.rpm$ $rsync_log_path/fc_updatelist_$(date +%Y%m%d))" ]; then
    grep \.rpm$ $rsync_log_path/fc_updatelist_$(date +%Y%m%d) | awk -F / '{print $NF}' | sort -u -V >> /tmp/update.list
    echo "Fedora has updated" >> /tmp/update.mail
  else
    echo "Fedora no update" >> /tmp/update.list
    echo "Fedora no update" >> /tmp/update.mail
  fi

  echo "Meego update list:" >> /tmp/update.list
  if [ -n "$(grep \.rpm$ $rsync_log_path/meego_updatelist_$(date +%Y%m%d))" ]; then
    grep \.rpm$ $rsync_log_path/meego_updatelist_$(date +%Y%m%d) | awk -F / '{print $NF}' | sort -u -V >> /tmp/update.list
    echo "Meego has updated" >> /tmp/update.mail
  else
    echo "Meego no update" >> /tmp/update.list
    echo "Meego no update" >> /tmp/update.mail
  fi
  cat /tmp/update.mail | mail -s "Update list" -a /tmp/update.list perngs@gmail.com
  rm /tmp/update.mail /tmp/update.list
}

function check_rpmmacros(){
  if [ ! -e "$HOME/.rpmmacros" ]; then
    echo -e "%_topdir\t\t%{getenv:HOME}/rpmbuild/%{name}" > $HOME/.rpmmacros
  elif [ -z "$(grep %_topdir $HOME/.rpmmacros 2> /dev/null)" ]; then
    echo -e "%_topdir\t\t%{getenv:HOME}/rpmbuild/%{name}" >> $HOME/.rpmmacros
  elif [ ! "$(grep '"%_topdir' $HOME/.rpmmacros | col -x | awk -F " " '{print $NF}')" = "%{getenv:HOME}/rpmbuild/%{name}" ]; then
    sed -i "s/^%_topdir.*$/%_topdir\t\t%{getenv:HOME}\/rpmbuild\/%{name}/g" $HOME/.rpmmacros
  fi
}

function upload_to_sl_git(){
  for srpm in $(cat $pkg_sync_dir/list/sl_git.list)
  do
    pkgname=$(rpm -qp --queryformat %{name}"\n" $sl_pkgs_path/$srpm)
    pkgver=$(rpm -qp  --queryformat %{version}-%{release}"\n" $sl_pkgs_path/$srpm)
    ssh $user@$git_ip "ls -ld $sl_git_path/$pkgname.git > /dev/null 2>&1";
    case "$?" in
      "2")
        ssh $user@$git_ip "mkdir $sl_git_path/$pkgname.git && cd $sl_git_path/$pkgname.git && git init --bare --shared"
        echo "create $pkgname.git successful"
        rpm -i $sl_pkgs_path/$srpm 2> /dev/null
        cp $pkg_sync_dir/Makefile $HOME/rpmbuild/$pkgname
        cd $HOME/rpmbuild/$pkgname
#        mkdir ossii || exit
#        cp -a SPECS/* ossii || exit
        git init
        git add . && git commit -m "upload $pkgname-$pkgver from scientific linux 6.2" 
        git remote add origin $user@$git_ip:$sl_git_path/$pkgname.git
        git push origin master
        git push origin master:refs/heads/develop
        git push origin master:refs/heads/official
        ;;
      "0")
        if [ -e "$HOME/rpmbuild/$pkgname" ]; then
          cd $HOME/rpmbuild/$pkgname
          git checkout official
          if [ -e "SOURCES" -o -e "SPECS" ]; then
            git rm -r SPECS SOURCES
          fi
          rpm -i $sl_pkgs_path/$srpm 2> /dev/null
          git add . && git commit -m "upload $pkgname-$pkgver from scientific linux 6.2"
          git push
        else
          mkdir -p $HOME/rpmbuild/$pkgname
          cd $HOME/rpmbuild/$pkgname
          git clone $user@$git_ip:$sl_git_path/$pkgname.git $HOME/rpmbuild/$pkgname
          git checkout -b official origin/official
          git rm -r SPECS SOURCES
          rpm -i $sl_pkgs_path/$srpm 2> /dev/null
          git add . && git commit -m "upload $pkgname-$pkgver from scientific linux 6.2"
          git push
        fi
        ;;
      *)
        echo "can not connect to git server"
        logger -i -p local5.notice -t pkg_rsync "can not connect to git server"
        exit 1
        ;;
    esac
    done
  }

function upload_to_fc_git(){
  if [ ! -e "$pkg_sync_dir/list/fc_git.list" ]; then
    echo "$pkg_sync_dir/list/sl_git.list not exist"
    logger -i -p local5.notice -t pkg_rsync "$pkg_sync_dir/list/fc_git.list not exist"
    exit 3
  fi
  for srpm in $(cat $pkg_sync_dir/list/fc_git.list)
  do
    pkgname=$(rpm -qp --queryformat %{name}"\n" $fc_pkgs_path/source/$srpm)
    pkgver=$(rpm -qp  --queryformat %{version}-%{release}"\n" $fc_pkgs_path/source/$srpm)
    ssh $user@$git_ip "ls -ld $fc_git_path/$pkgname.git > /dev/null 2>&1";
    case "$?" in
      "2")
        ssh $user@$git_ip "mkdir $fc_git_path/$pkgname.git && cd $fc_git_path/$pkgname.git && git init --bare --shared"
        echo "create $pkgname.git successful"
        rpm -i $fc_pkgs_path/source/$srpm 2> /dev/null
        cp $pkg_sync_dir/Makefile $HOME/rpmbuild/$pkgname
        cd $HOME/rpmbuild/$pkgname
#        mkdir ossii || exit
#        cp -a SPECS/* ossii || exit
        git init
        git add . && git commit -m "upload $pkgname-$pkgver from Fedora 17" 
        git remote add origin $user@$git_ip:$fc_git_path/$pkgname.git
        git push origin master
        git push origin master:refs/heads/develop
        git push origin master:refs/heads/official
        ;;
      "0")
        if [ -e "$HOME/rpmbuild/$pkgname" ]; then
          cd $HOME/rpmbuild/$pkgname
          git checkout official
          if [ -e "SOURCES" -o -e "SPECS" ]; then
            git rm -r SPECS SOURCES
          fi
          rpm -i $sl_pkgs_path/source/$srpm 2> /dev/null
          git add . && git commit -m "upload $pkgname-$pkgver from Fedora 17"
          git push
        else
          mkdir -p $HOME/rpmbuild/$pkgname
          cd $HOME/rpmbuild/$pkgname
          git clone $user@$git_ip:$fc_git_path/$pkgname.git $HOME/rpmbuild/$pkgname
          git checkout -b official origin/official
          git rm -r SPECS SOURCES
          rpm -i $fc_pkgs_path/source/$srpm 2> /dev/null
          git add . && git commit -m "upload $pkgname-$pkgver from Fedora 17"
          git push
        fi
        ;;
      *)
        echo "can not connect to git server"
        exit 1
        ;;
    esac
    done
}

function upload_to_meego_git(){
  rm $rsync_log_path/meego_updatelist_$(date +%Y%m%d) 2> /dev/null
  if [ ! -e "$pkg_sync_dir/list/meego_git.list" ]; then
    echo "$pkg_sync_dir/list/sl_git.list not exist"
    logger -i -p local5.notice -t pkg_rsync "$pkg_sync_dir/list/meego_git.list not exist"
    exit 4
  fi
  for srpm in $(cat $pkg_sync_dir/list/meego_git.list)
  do
    pkgname=$(rpm -qp --queryformat %{name}"\n" $meego_pkgs_path/$srpm)
    pkgver=$(rpm -qp  --queryformat %{version}-%{release}"\n" $meego_pkgs_path/$srpm)
    ssh $user@$git_ip "ls -ld $meego_git_path/$pkgname.git > /dev/null 2>&1";
    case "$?" in
      "2")
        ssh $user@$git_ip "mkdir $meego_git_path/$pkgname.git && cd $meego_git_path/$pkgname.git && git init --bare --shared"
        echo "create $pkgname.git successful"
        rpm -i $meego_pkgs_path/$srpm 2> /dev/null
        cp $pkg_sync_dir/Makefile $HOME/rpmbuild/$pkgname
        cd $HOME/rpmbuild/$pkgname
#        mkdir ossii || exit
#        cp -a SPECS/* ossii || exit
        git init
        git add . && git commit -m "upload $pkgname-$pkgver from meego 1.2" 
        git remote add origin $user@$git_ip:$meego_git_path/$pkgname.git
        git push origin master
        git push origin master:refs/heads/develop
        git push origin master:refs/heads/official
        ;;
      "0")
        if [ -e "$HOME/rpmbuild/$pkgname" ]; then
          cd $HOME/rpmbuild/$pkgname
          git checkout official
          if [ -e "SOURCES" -o -e "SPECS" ]; then
            git rm -r SPECS SOURCES
          fi
          rpm -i $meego_pkgs_path/repos/$srpm 2> /dev/null
          git add . && git commit -m "upload $pkgname-$pkgver from meego 1.2" 
          git push
        else
          mkdir -p $HOME/rpmbuild/$pkgname
          cd $HOME/rpmbuild/$pkgname
          git checkout -b official origin/official
          git rm -r SPECS SOURCES
          rpm -i $meego_pkgs_path/repos/$srpm 2> /dev/null
          git add . && git commit -m "upload $pkgname-$pkgver from meego 1.2" 
          git push
        fi
        ;;
      *)
        echo "can not connect to git server"
        exit 1
        ;;
    esac
    done
}

function update_sl_repo() {
  rsync -av --delete $sl_mirror_site/i386/os/repodata $sl_pkgs_path/i386/os
  rsync -av --delete $sl_mirror_site/x86_64/os/repodata $sl_pkgs_path/x86_64/os
}
function update_fc_repo() {
  rsync -av --delete $fc_mirror_site/i386/os/repodata $fc_pkgs_path/i386/os
  rsync -av --delete $fc_mirror_site/x86_64/os/repodata $fc_pkgs_path/x86_64/os
  rsync -av --delete $fc_mirror_site/source/SRPMS/repodata $fc_pkgs_path/source/SRPMS
  rsync -av --delete $fc_arm_mirror_site/arm/os/repodata $fc_pkgs_path/arm/os
  rsync -av --delete $fc_arm_mirror_site/armhfp/os/repodata $fc_pkgs_path/armhfp/os
}
function update_meego_repo() {
  rsync -av --delete $meego_mirror_site/repos/non-oss/armv7hl/packages/repodata $meego_pkgs_path/repos/non-oss/armv7hl/packages
  rsync -av --delete $meego_mirror_site/repos/non-oss/ia32/packages/repodata $meego_pkgs_path/repos/non-oss/ia32/packages
  rsync -av --delete $meego_mirror_site/repos/non-oss/source/repodata $meego_pkgs_path/repos/non-oss/ia32/source
  rsync -av --delete $meego_mirror_site/repos/oss/armv7hl/packages/repodata $meego_pkgs_path/repos/oss/armv7hl/packages
  rsync -av --delete $meego_mirror_site/repos/oss/ia32/packages/repodata $meego_pkgs_path/repos/oss/ia32/packages
  rsync -av --delete $meego_mirror_site/repos/oss/source/repodata $meego_pkgs_path/repos/oss/ia32/source
}



case "$1" in
  "all")
    rm -rf $HOME/rpmbuild/*
    sl_pkgs_download;
    fc_pkgs_download;
    meego_pkgs_download;
    send_mail;
    check_rpmmacros;
    upload_to_sl_git;
    cd ~ && rm -rf $HOME/rpmbuild/*
    upload_to_fc_git;
    cd ~ && rm -rf $HOME/rpmbuild/*
    upload_to_meego_git;
    cd ~ && rm -rf $HOME/rpmbuild/*
    update_sl_repo;
    update_fc_repo;
    update_meego_repo;
    ;;
  "sl")
    rm -rf $HOME/rpmbuild/*
    sl_pkgs_download;
    send_mail;
    check_rpmmacros;
    upload_to_sl_git;
    cd ~ && rm -rf $HOME/rpmbuild/*
    update_sl_repo;
    ;;
  "fc")
    rm -rf $HOME/rpmbuild/*
    fc_pkgs_download;
    send_mail;
    check_rpmmacros;
    upload_to_fc_git;
    cd ~ && rm -rf $HOME/rpmbuild/*
    update_fc_repo;
    ;;
  "meego")
    rm -rf $HOME/rpmbuild/*
    meego_pkgs_download;
    send_mail;
    check_rpmmacros;
    upload_to_meego_git;
    cd ~ && rm -rf $HOME/rpmbuild/*
    update_meego_repo;
    ;;
  *)
    echo $"Usage: $0 {all|sl|fc|meego}"
    echo "all		:sync Fedora's、Meego's RPM and SRPM and Scientificlinux's releases RPM"
    echo "sl		:sync Scientificlinux's releases RPM"
    echo "fc		:sync Fedora's releases RPM and SRPM"
    echo "meego		:sync Meego's releases RPM and SRPM"
    exit
    ;;
esac

