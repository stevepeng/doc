#!/bin/bash
export PATH=/sbin:/bin:/usr/bin:/usr/sbin
export user=git
export git_ip=127.0.0.1
export sl_srpm_path=/var/yum/scientific/6.2
export fc_srpm_path=/var/yum/fedora/updates/17
export sl_git_path=/var/git/packages/scientific/6.2
export fc_git_path=/var/git/packages/fedora/17
export fc_git_path=/var/git/packages/meego/1.2.0

function check_rpmmacros(){
  if [ ! -e "$HOME/.rpmmacros" ]; then
    echo -e "%_topdir\t\t%{getenv:HOME}/rpmbuild/%{name}" > $HOME/.rpmmacros
  elif [ -z "`grep %_topdir $HOME/.rpmmacros 2> /dev/null`" ]; then
    echo -e "%_topdir\t\t%{getenv:HOME}/rpmbuild/%{name}" >> $HOME/.rpmmacros
  elif [ ! "`grep '"%_topdir' $HOME/.rpmmacros | col -x | awk -F " " '{print $NF}'`" = "%{getenv:HOME}/rpmbuild/%{name}" ]; then
    sed -i "s/^%_topdir.*$/%_topdir\t\t%{getenv:HOME}\/rpmbuild\/%{name}/g" $HOME/.rpmmacros
  fi
}

function upload_sl_srpm(){
  for srpm in `cat sl_list.txt`
  do
    pkgname=`rpm -qp --queryformat %{name}"\n" $sl_srpm_path/$srpm` || exit 2
    pkgver=`rpm -qp  --queryformat %{version}-%{release}"\n" $sl_srpm_path/$srpm`
    ssh $user@$git_ip "ls -ld $sl_git_path/$pkgname.git > /dev/null 2>&1";
    case "$?" in
      "2")
        ssh $user@$git_ip "mkdir $sl_git_path/$pkgname.git && cd $sl_git_path/$pkgname.git && git init --bare --shared"
        echo "create $pkgname.git successful"
        rpm -i $sl_srpm_path/$srpm 2> /dev/null
        cd $HOME/rpmbuild/$pkgname
        git init
        git add . && git commit -m "upload $pkgname-$pkgver" 
        git remote add origin $user@$git_ip:$sl_git_path/$pkgname.git
        git push origin master
        ;;
      "0")
        if [ -e "$HOME/rpmbuild/$pkgname" ]; then
          cd $HOME/rpmbuild/$pkgname
          git clone $user@$git_ip:$sl_git_path/$pkgname.git $HOME/rpmbuild/$pkgname
          git rm -r SPECS SOURCES
          rpm -i $sl_srpm_path/$srpm 2> /dev/null
          git add . && git commit -m "upload $pkgname-$pkgver" && git push
        else
          rpm -i $sl_srpm_path/$srpm 2> /dev/null
          cd $HOME/rpmbuild/$pkgname
          git add . && git commit -m "upload $pkgname-$pkgver" && git push
        fi
        ;;
      *)
        echo "can not connect to git server"
        exit 1
        ;;
    esac
    done
  }

function upload_fc_srpm(){
  for srpm in `cat fc_list.txt`
  do
    pkgname=`rpm -qp --queryformat %{name}"\n" $fc_srpm_path/$srpm` || exit 2
    pkgver=`rpm -qp  --queryformat %{version}-%{release}"\n" $fc_srpm_path/$srpm`
    ssh $user@$git_ip "ls -ld $fc_git_path/$pkgname.git > /dev/null 2>&1";
    case "$?" in
      "2")
        ssh $user@$git_ip "mkdir $fc_git_path/$pkgname.git && cd $fc_git_path/$pkgname.git && git init --bare --shared"
        echo "create $pkgname.git successful"
        rpm -i $fc_srpm_path/$srpm 2> /dev/null
        cd $HOME/rpmbuild/$pkgname
        git init
        git add . && git commit -m "upload $pkgname-$pkgver" 
        git remote add origin $user@$git_ip:$fc_git_path/$pkgname.git
        git push origin master
        rm -rf $HOME/rpmbuild/$pkgname
        ;;
      "0")
        if [ -e "$HOME/rpmbuild/$pkgname" ]; then
          cd $HOME/rpmbuild/$pkgname
          git clone $user@$git_ip:$fc_git_path/$pkgname.git $HOME/rpmbuild/$pkgname
          git rm -r SPECS SOURCES
          rpm -i $fc_srpm_path/$srpm 2> /dev/null
          git add . && git commit -m "upload $pkgname-$pkgver" && git push
        else
          rpm -i $sl_srpm_path/$srpm 2> /dev/null
          cd $HOME/rpmbuild/$pkgname
          git add . && git commit -m "upload $pkgname-$pkgver" && git push
        fi  
        ;;
      *)
        echo "can not connect to git server"
        exit 1
        ;;
    esac
    done
}

function upload_meego_srpm(){
  for srpm in `cat meego_list.txt`
  do
    pkgname=`rpm -qp --queryformat %{name}"\n" $meego_srpm_path/$srpm` || exit 2
    pkgver=`rpm -qp  --queryformat %{version}-%{release}"\n" $meego_srpm_path/$srpm`
    ssh $user@$git_ip "ls -ld $meego_git_path/$pkgname.git > /dev/null 2>&1";
    case "$?" in
      "2")
        ssh $user@$git_ip "mkdir $meego_git_path/$pkgname.git && cd $meego_git_path/$pkgname.git && git init --bare --shared"
        echo "create $pkgname.git successful"
        rpm -i $meego_srpm_path/$srpm 2> /dev/null
        cd $HOME/rpmbuild/$pkgname
        git init
        git add . && git commit -m "upload $pkgname-$pkgver" 
        git remote add origin $user@$git_ip:$meego_git_path/$pkgname.git
        git push origin master
        ;;
      "0")
        if [ -e "$HOME/rpmbuild/$pkgname" ]; then
          cd $HOME/rpmbuild/$pkgname
          git rm -r SPECS SOURCES
          git clone $user@$git_ip:$meego_git_path/$pkgname.git $HOME/rpmbuild/$pkgname
          rpm -i $meego_srpm_path/$srpm 2> /dev/null
          git add . && git commit -m "upload $pkgname-$pkgver" && git push
        else
          rpm -i $sl_srpm_path/$srpm 2> /dev/null
          cd $HOME/rpmbuild/$pkgname
          git add . && git commit -m "upload $pkgname-$pkgver" && git push
        fi
        ;;
      *)
        echo "can not connect to git server"
        exit 1
        ;;
    esac
    done
}

check_rpmmacros;
upload_sl_srpm;
upload_fc_srpm;
upload_meego_srpm;
rm -rf $HOME/rpmbuild
