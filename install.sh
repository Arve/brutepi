#!/bin/bash

set -e

select_dac ()
{
  echo "Select your DAC:"
  echo "0) Abort installation of BrutePi"
  # echo "$@"
  select option; do # in "$@" is the default
    if [ "$REPLY" -eq "0" ];
    then
      echo "Exiting..."
      exit 1 
      break
    elif [ 1 -le "$REPLY" ] && [ "$REPLY" -le $(($#)) ];
    then
      DAC=$option
      break;
    else
      echo "Incorrect Input: Select a number 1-$#"
    fi
  done
}

if [[ $UID != 0 ]]; then
    echo "This script needs to use sudo:"
    echo "sudo $0 $*"
    exit 1
fi

if [ `grep  "Raspbian" /etc/issue | wc -l` -lt 1 ] ; then 
    echo "ABORTING: Script is only intended for running on Raspbian distributions"
    exit 1
fi


if ! [ -f "fir/left.wav" ]; then
    echo -n "ERROR: Missing convolution file fir/left.wav for left audio channel."
    echo -n "Make sure fir/left.wav (and fir/right.wav) exists and rerun script. "
    exit 1
fi

if ! [ -f "fir/right.wav" ]; then
    echo -n "ERROR: Missing convolution file fir/right.wav for right audio channel."
    echo -n "Make sure  fir/right.wav (and fir/left.wav exists and rerun script. "
    exit 1
fi


echo "This script will install BruteFIR and shairport-sync on a standard Raspbian installation."
echo
echo -n "Please enter a name for your device. Press return to use default (" `hostname` ")"
echo
echo -n "Name: "
read devname

## Blacklist onboard sound, and install snd-aloop

echo "Setting up audio devices"

MODULE="snd_bcm2835"
if lsmod | grep "$MODULE" &> /dev/null ; then
  echo "Removing $MODULE"
  rmmod $MODULE
fi

MODULE="snd-aloop"
if lsmod | grep "$MODULE" &> /dev/null ; then
  echo "$MODULE already loaded" 
else
  echo "Loading $MODULE"
  modprobe snd-aloop
fi


## Query for output DAC

declare DAC
declare -a DACS
DACS=( $(aplay -l | grep "card" | grep -v "Loopback" | awk '{print $3}') )

select_dac "${DACS[@]}"

echo "Selected $DAC"

## Install packages. 

echo "Installing updates"
# sudo apt-get update
# sudo apt-get upgrade
sudo apt-get install autoconf automake avahi-daemon build-essential brutefir git libasound2-dev libavahi-client-dev libconfig-dev libdaemon-dev libpopt-dev libsoxr-dev  libssl-dev libtool sox xmltoman

mkdir -p tmp
cd tmp

## Install shairport-sync
echo "Installing shairport-sync"
git clone https://github.com/mikebrady/shairport-sync.git
cd shairport-sync
git checkout development
git pull
autoreconf -fi
./configure --sysconfdir=/etc --with-alsa --with-avahi --with-ssl=openssl --with-metadata --with-soxr --with-systemd
make
make install
cd ../..


sed -e "s/OUTPUT_DAC/$DAC/g" config/brutefir_config > /etc/brutefir_config
sed -e "s/OUTPUT_DAC/$DAC/g" config/shairport-sync.conf > /etc/shairport-sync.conf

if [ -n "$devname" ]; then
    sed -i -e "s/\%H/$devname/" /etc/shairport-sync.conf
fi

cp config/brutefir.service /lib/systemd/system/

mkdir -p /home/shairport-sync

sox fir/left.wav -b 32 -e signed-integer -c 1 -r 44100 -t raw /home/shairport-sync/left.raw
sox fir/right.wav -b 32 -e signed-integer -c 1 -r 44100 -t raw /home/shairport-sync/right.raw

chown -R shairport-sync:shairport-sync /home/shairport-sync

systemctl enable brutefir.service
systemctl enable shairport-sync.service

## Now on to the ugly truths of system tweaking

for i in `pgrep ksoftirqd`; do chrt -p 99 $i; done


# Tweaks. Yes.  Patching rc.local is a tad ugly, but required
cp /etc/rc.local /etc/rc.local.old
echo "Patching /etc/rc.local - original file copied to /etc/rc.local.old"

sed -i -e "s/exit 0/for irqdps in \`pgrep ksoftirqd\`; do chrt -p 99 \$irqdps; done\n/" /etc/rc.local
echo -e "echo \"performance\" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor\n" >> /etc/rc.local
echo -e "\n\nexit 0" >> /etc/rc.local

## Change default swappiness
sysctl -w vm.swappiness=1

cp /etc/sysctl.conf /etc/sysctl.conf.old
echo "Patching /etc/sysctl.conf - original file copied to /etc/sysctl.conf.old"

echo -e "\nvm.swappiness=1" >> /etc/sysctl.conf

systemctl start brutefir
systemctl start shairport-sync

cd ..

echo "Cleaning up … "
echo "options snd-aloop index=0 pcm_substreams=1" > /etc/modprobe.d/snd-aloop.conf
echo "snd-aloop" > /etc/modules-load.d/snd-aloop.conf
echo "blacklist snd_bcm2835" > /etc/modprobe.d/blacklist-snd_2835.conf

rm -rf tmp

echo "Done!"



exit 0
