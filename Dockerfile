FROM docker.io/archlinux:latest

RUN pacman -Syu --noconfirm
RUN pacman -S git grub archiso --noconfirm

COPY iso/* root/iso/
COPY build.sh root/build.sh 

RUN ["mkdir", "/out"]
ENTRYPOINT ["/bin/sh", "/root/build.sh"]