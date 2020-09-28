#!/bin/sh
#build 3
set -u

# This script will create swap.swp file in STORAGE_NAME volume for enable swap memory. 

# Copyright (C) 2020 Sleeping Coconut https://sleepingcoconut.com

#----------VARIABLES----------
STORAGE_NAME="IMPERIAL"
SWAP_SIZE="524288"

UPDATE_INTERVAL=15

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
  cat > "/tmp/mnt/"$STORAGE_NAME"/asusware/etc/init.d/S99coswapperdset" <<EOF
#!/bin/sh
#
#----------VARIABLES----------
STORAGE_NAME="$STORAGE_NAME"
INTERVAL="$UPDATE_INTERVAL"
#
#----------SCRIPT----------
cru a coswapperd "*/"\$INTERVAL" * * * *" /tmp/mnt/"\$STORAGE_NAME"/coswapperd.sh -on
EOF
chmod +x /tmp/mnt/"$STORAGE_NAME"/asusware/etc/init.d/S99coswapperdset
}

disableAutoboot() {
  cru d coswapperd
  swapoff -a
  rm /tmp/mnt/"$STORAGE_NAME"/asusware/lib/ipkg/info/coswapperdset.control &>/dev/null
  rm /tmp/mnt/"$STORAGE_NAME"/asusware/etc/init.d/S99coswapperdset &>/dev/null
  rm /tmp/mnt/"$STORAGE_NAME"/asusware/S99coswapperdset.1 &>/dev/null
}

cleanAutoboot() {                                                                       
  cru d coswapperd                                                                      
  swapoff -a                                                                            
  rm -R /tmp/mnt/"$STORAGE_NAME"/asusware &>/dev/null                                   
}

startSwap() {
  cru a coswapperd "*/$UPDATE_INTERVAL * * * *" /tmp/mnt/$STORAGE_NAME/coswapperd.sh -on
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
                        enableAutoboot || { log "move failed enabling"; exit 1; }
                        exit 0
                        ;;
      -d | --disable )  log "Disabling coswapperd..." >> /tmp/syslog.log
                        disableAutoboot || { log "swap failed disabling"; exit 1; }
                        exit 0
                        ;;
      -c | --clean )    log "Cleaning coswapperd and ASUSWRT autoboot..." >> /tmp/syslog.log
                        cleanAutoboot || { log "swap failed cleaning autoboot"; exit 1; }
                        exit 0
                        ;;
      -on | --start )   if [ "$SWAP_SIZE_NOW" -eq 0 ];
                        then
                          log "Starting swap..." >> /tmp/syslog.log
                          startSwap || { log "swap failed starting"; exit 1; }
                        else
                          log "Swap previously started" >> /tmp/syslog.log    
                        fi
                        exit 0
                        ;;
      -off | --stop )   log "Stopping swap..." >> /tmp/syslog.log
                        stopSwap || { log "swap failed stopping"; exit 1; }
                        exit 0
                        ;;
      * )               usage
                        exit 1
    esac
    shift
  done
fi