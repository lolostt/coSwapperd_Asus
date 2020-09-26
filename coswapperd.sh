#!/bin/sh
#build 3

# This script will create swap.swp file in STORAGE_NAME volume for enable swap memory. 

# Copyright (C) 2020 Sleeping Coconut https://sleepingcoconut.com

#----------VARIABLES----------#
SWAP_SIZE="524288"

# Zero Clause BSD license {{{
#
# Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL 
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, 
# INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN 
# AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE 
# OF THIS SOFTWARE.
# }}}

#----------FUNCTIONS----------
log() { logger -t coswapperd -s $*; }

usage() {
  echo "usage: `basename $0` [-e | -d | -on | -off]"
}

enableAutoboot() {
  mkdir /tmp/mnt/"$STORAGE_NAME"/asusware &>/dev/null
  mkdir /tmp/mnt/"$STORAGE_NAME"/asusware/etc &>/dev/null
  mkdir /tmp/mnt/"$STORAGE_NAME"/asusware/etc/init.d &>/dev/null
  mkdir /tmp/mnt/"$STORAGE_NAME"/asusware/lib &>/dev/null
  mkdir /tmp/mnt/"$STORAGE_NAME"/asusware/lib/ipkg &>/dev/null
  mkdir /tmp/mnt/"$STORAGE_NAME"/asusware/lib/ipkg/info &>/dev/null
  touch /tmp/mnt/"$STORAGE_NAME"/asusware/.asusrouter
  writeControl
  writeS99
  log "You should reboot router NOW" >> /tmp/syslog.log
}

writeControl() {
  echo "Enabled: yes" > /tmp/mnt/"$STORAGE_NAME"/asusware/lib/ipkg/info/coswapperdset.control
}

writeS99() {
  cat > "/mnt/"$STORAGE_NAME"/asusware/etc/init.d/S99coswapperdset" <<EOF
#!/bin/sh
#
#
STORAGE_NAME="$STORAGE_NAME"
INTERVAL="15"
#
#
cru a coswapperd "*/"\$INTERVAL" * * * *" /mnt/"\$STORAGE_NAME"/coswapperd.sh -on
EOF
chmod +x /tmp/mnt/"$STORAGE_NAME"/asusware/etc/init.d/S99coswapperdset
}

disableAutoboot() {
  cru d coswapperd
  swapoff -a
  rm /tmp/mnt/"$STORAGE_NAME"/asusware/lib/ipkg/info/coswapperdset.control &>/dev/null
  rm /tmp/mnt/"$STORAGE_NAME"/asusware/etc/init.d/S99coswapperdset &>/dev/null
}

cleanAutoboot() {                                                                       
  cru d coswapperd                                                                      
  swapoff -a                                                                            
  rm -R /tmp/mnt/"$STORAGE_NAME"/asusware &>/dev/null                                   
}

startSwap() {
  sleep 180
  rm /tmp/mnt/"$STORAGE_NAME"/swap.swp &>/dev/null
  dd if=/dev/zero of=/tmp/mnt/"$STORAGE_NAME"/swap.swp bs=1k count="$SWAP_SIZE"
  mkswap /tmp/mnt/"$STORAGE_NAME"/swap.swp                                   
  swapon /tmp/mnt/"$STORAGE_NAME"/swap.swp
  log "Swap started" >> /tmp/syslog.log
}

stopSwap() {
  cru d coswapperd
  swapoff -a
  log "You should (hard) reboot router NOW" >> /tmp/syslog.log
}

#----------SCRIPT----------
SWAP_SIZE_NOW=`free | head -3 | tail -1 | awk '{print $2}'`

if [ $# -lt 1 ]; then
  usage
else
  while [ "$1" != "" ]; do
    case $1 in
      -e | --enable )   log "Enabling coswapperd..." >> /tmp/syslog.log
                        echo -n "->Please write USB storage volume name: "
                        read STORAGE_NAME
                        enableAutoboot
                        exit 0
                        ;;
      -d | --disable )  log "Disabling coswapperd..." >> /tmp/syslog.log
                        echo -n "->Please write USB storage volume name: "
                        read STORAGE_NAME
                        disableAutoboot
                        exit 0
                        ;;
      -c | --clean )    log "Cleaning coswapperd and ASUSWRT autoboot..." >> /tmp/syslog.log
                        echo -n "->Please write USB storage volume name: "
                        read STORAGE_NAME
                        cleanAutoboot
                        exit 0
                        ;;
      -on | --start )   if [ "$SWAP_SIZE_NOW" -eq 0 ];
                        then
                          log "Starting swap..." >> /tmp/syslog.log
                          startSwap
                        else
                          log "Swap previously started" >> /tmp/syslog.log    
                        fi
                        exit 0
                        ;;
      -off | --stop )   log "Stopping swap..." >> /tmp/syslog.log
                        stopSwap
                        exit 0
                        ;;
      * )               usage
                        exit 1
    esac
    shift
  done
fi