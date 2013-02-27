#!/bin/sh
sudo mount -o loop dos622.img  /mnt/
sudo cp -v process.com  /mnt/
sudo cp -v simple_proc.com  /mnt/sp.com
sudo umount /mnt/

