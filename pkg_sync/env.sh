#!/bin/bash
export PATH=/sbin:/bin:/usr/sbin:/usr/sbin

read -p "Input Scientific Linux yum location: " sl_yum_path
if [ ! -d "$sl_yum_path" ]; then
  read -p "$sl_yum_path has exist,delete $sl_yum_path?" del_sl_yum_path
    if [ "del_sl_yum_path" == "y" ]; then
      rm -rf $sl_yum_path


read -p "Input Fedora yum location: " fc_yum_path
read -p "Input Meego yum location: " meego_yum_path
echo "Scientific Linux yum location: $sl_yum_path" 
echo "Fedora yum location: $fc_yum_path"
echo "Meego yum location: $meego_yum_path"
