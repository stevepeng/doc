#!/bin/bash
export PATH=/sbin:/bin:/usr/sbin:/usr/bin
user=git
git_ip=192.168.1.90
pkg_sync_dir=$(pwd)
ox3_pkgs_path=
ox3_git_path=/data/git/oxos_project/3/os
ox3_pkgs_path=
ox3_git_path=/data/git/oxos_project/3/os

function check_rpmmacros(){
  if [ ! -e "$HOME/.rpmmacros" ]; then
    echo -e "%_topdir\t\t%{getenv:HOME}/rpmbuild/%{name}" > $HOME/.rpmmacros
  elif [ -z "$(grep %_topdir $HOME/.rpmmacros 2> /dev/null)" ]; then
    echo -e "%_topdir\t\t%{getenv:HOME}/rpmbuild/%{name}" >> $HOME/.rpmmacros
  elif [ ! "$(grep '"%_topdir' $HOME/.rpmmacros | col -x | awk -F " " '{print $NF}')" = "%{getenv:HOME}/rpmbuild/%{name}" ]; then
    sed -i "s/^%_topdir.*$/%_topdir\t\t%{getenv:HOME}\/rpmbuild\/%{name}/g" $HOME/.rpmmacros
  fi
}

function upload_to_ox3_git(){
  for srpm in $(cat $pkg_sync_dir/list/ox3_git.list)
  do
#    pkgname=$(rpm -qp --queryformat %{name}"\n" $ox3_pkgs_path/$srpm)
#    pkgver=$(rpm -qp  --queryformat %{version}-%{release}"\n" $ox3_pkgs_path/$srpm)
    pkgname=$(rpm -qp --queryformat %{name}"\n" $srpm)
    pkgver=$(rpm -qp  --queryformat %{version}-%{release}"\n" $srpm)
    ssh $user@$git_ip "ls -ld $ox3_git_path/$pkgname.git > /dev/null 2>&1";
    case "$?" in
      "2")
        ssh $user@$git_ip "mkdir $ox3_git_path/$pkgname.git && cd $ox3_git_path/$pkgname.git && git init --bare --shared"
        echo "create $pkgname.git successful"
#        rpm -i $ox3_pkgs_path/$srpm 2> /dev/null || exit
        rpm -i $srpm 2> /dev/null || exit
        cp $pkg_sync_dir/Makefile $HOME/rpmbuild/$pkgname
        cd $HOME/rpmbuild/$pkgname
        mkdir ossii || exit
        cp -a SPECS/* ossii || exit
        git init
        git add . && git commit -m "upload $pkgname-$pkgver from OX 3" 
        git remote add origin $user@$git_ip:$ox3_git_path/$pkgname.git
        git push origin master
        git push origin master:refs/heads/develop
        ;;
      "0")
        if [ -e "$HOME/rpmbuild/$pkgname" ]; then
          cd $HOME/rpmbuild/$pkgname
          git checkout develop
          if [ -e "SOURCES" -o -e "SPECS" ]; then
            git rm -r SPECS SOURCES
          fi
          rpm -i $srpm 2> /dev/null
          git add . && git commit -m "upload $pkgname-$pkgver from OX 3"
          git push
        else
          mkdir -p $HOME/rpmbuild/$pkgname
          cd $HOME/rpmbuild/$pkgname
          git checkout -b develop origin/develop
          git rm -r SPECS SOURCES
          rpm -i $srpm 2> /dev/null
          git add . && git commit -m "upload $pkgname-$pkgver from OX 3" 
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
  for srpm in $(cat $pkg_sync_dir/list/fc_git.list)
  do
#    pkgname=$(rpm -qp --queryformat %{name}"\n" $fc_pkgs_path/$srpm)
#    pkgver=$(rpm -qp  --queryformat %{version}-%{release}"\n" $fc_pkgs_path/$srpm)
    pkgname=$(rpm -qp --queryformat %{name}"\n" $srpm)
    pkgver=$(rpm -qp  --queryformat %{version}-%{release}"\n" $srpm)
    ssh $user@$git_ip "ls -ld $ox3_git_path/$pkgname.git > /dev/null 2>&1";
    case "$?" in
      "2")
        ssh $user@$git_ip "mkdir $ox3_git_path/$pkgname.git && cd $ox3_git_path/$pkgname.git && git init --bare --shared"
        echo "create $pkgname.git successful"
#        rpm -i $fc_pkgs_path/$srpm 2> /dev/null || exit
        rpm -i $srpm 2> /dev/null || exit
        cp $pkg_sync_dir/Makefile $HOME/rpmbuild/$pkgname
        cd $HOME/rpmbuild/$pkgname
        git init
        git add . && git commit -m "upload $pkgname-$pkgver from Fedora 17" 
        git remote add origin $user@$git_ip:$ox3_git_path/$pkgname.git
        git push origin master
        git push origin master:refs/heads/develop
        ;;
      "0")
        if [ -e "$HOME/rpmbuild/$pkgname" ]; then
          cd $HOME/rpmbuild/$pkgname
          git checkout develop
          if [ -e "SOURCES" -o -e "SPECS" ]; then
            git rm -r SPECS SOURCES
          fi
          rpm -i $srpm 2> /dev/null
          git add . && git commit -m "upload $pkgname-$pkgver from Fedora 17"
          git push
        else
          mkdir -p $HOME/rpmbuild/$pkgname
          cd $HOME/rpmbuild/$pkgname
          git checkout -b develop origin/develop
          git rm -r SPECS SOURCES
          rpm -i $srpm 2> /dev/null
          git add . && git commit -m "upload $pkgname-$pkgver from Fedora 17" 
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

if [ ! -e "$pkg_sync_dir/list/ox3_git.list" ]; then
  echo "$pkg_sync_dir/list/ox3_git.list not exist"
  logger -i -p local5.notice -t pkg_rsync "$pkg_sync_dir/list/ox3_git.list not exist"
  exit 2
elif [ ! -e "$pkg_sync_dir/list/fc_git.list" ]; then
  echo "$pkg_sync_dir/list/fc_git.list not exist"
  logger -i -p local5.notice -t pkg_rsync "$pkg_sync_dir/list/ox3_git.list not exist"
  exit 2
fi

check_rpmmacros;
#upload_to_ox3_git;
upload_to_fc_git;
cd ~ && rm -rf $HOME/rpmbuild/*
