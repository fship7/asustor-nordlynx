FROM ubuntu:18.04 AS build

RUN apt update && apt install -y libelf-dev build-essential pkg-config git rsync flex bison libssl-dev bc kmod wget

WORKDIR /tmp

RUN wget -O linux-5.4.x-x86_64.config https://sourceforge.net/projects/asgpl/files/ADM4.0.0/linux-5.4.x-x86_64.config/download &&\
  wget -O GPL_linux-5.4.x.tar.bz2 https://sourceforge.net/projects/asgpl/files/ADM4.0.0/GPL_linux-5.4.x.tar.bz2/download &&\
  tar -xvf GPL_linux-5.4.x.tar.bz2 &&\
  mkdir -p /lib/modules/5.4.x/build &&\
  cp -r linux-5.4.x-x86_64.config /lib/modules/5.4.x/build/.config &&\
  make -C ./linux-5.4.x modules_prepare O=/lib/modules/5.4.x/build &&\
  git clone https://git.zx2c4.com/wireguard-linux-compat &&\
  sed -i -e 's/COMPAT_VERSION/5/' -e 's/COMPAT_PATCHLEVEL/4/' -e 's/COMPAT_SUBLEVEL/50/' wireguard-linux-compat/src/compat/version/linux/version.h &&\
  make -C wireguard-linux-compat/src -j$(nproc) &&\
  cp /tmp/wireguard-linux-compat/src/wireguard.ko /root
  
CMD ["/bin/sh", "-c", "echo 'It works!'"]
