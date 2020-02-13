#!/bin/sh
MDIR=/mnt
sudo mount -o loop dos622.img  $MDIR
sudo cp -v process.com  $MDIR
sudo cp -v simple_proc.com  $MDIR
sudo cp -v simple_proc_signal.com  /mnt/sps.com
sudo umount $MDIR
