#!/bin/sh
sudo mount -o loop dos622.img  /mnt/
sudo cp -v *.com  /mnt/
sudo umount /mnt/

