#!/bin/sh
sudo mount -o loop dos622.img  /mnt/
sudo cp -v process.com  /mnt/
sudo cp -v simple_proc.com  /mnt/sp.com
sudo cp -v simple_proc_signal.com  /mnt/sps.com
sudo umount /mnt/

