# brutepi

Automating installation and configuration of BruteFIR and shairport-sync for Raspberry Pi

## Introduction

This script is used to ease the installation of shairport-sync and BruteFIR 

## Prerequisites

Before you start, it's assumed that you have some familiarity with all of the above:

1. Familiar with installing [Raspbian Jessie Lite](https://www.raspberrypi.org/downloads/raspbian/) on a Raspberry Pi of your choice - [Instructions here](https://www.raspberrypi.org/documentation/installation/installing-images/README.md)
2. Capable of setting up [WiFi via the command line](https://www.raspberrypi.org/documentation/configuration/wireless/wireless-cli.md)
3. Somewhat familiar with the bash shell.
4. Room correction using software like [Room EQ Wizard](https://www.roomeqwizard.com/).

## Exporting and converting impulse responses

After you have created your correction filters in Room EQ Wizard, you need to export them using:

    File -> Export -> Export Filters Impulse Response as WAV

When exporting export each channel individually using the following settings:

1. Mono
2. 32-bit
3. Check "Normalize samples to peak value"
4. Save the filter for the left channel as "left-fir.wav", and the right channel as "right-fir.wav"

Save the files in the `impulses` subreddit.

## Preparing the Raspberry Pi installation before first boot

Before continuing:

1. [Download Raspbian Jessie Lite](https://www.raspberrypi.org/downloads/raspbian/)
2. [Install the downloaded Raspbian](https://www.raspberrypi.org/documentation/installation/installing-images/README.md))

### Enable SSH

Since this Raspberry Pi installation will run as a headless installation (no keyboard or display connected), we'll need to enable SSH.  Do this by creating an empty text file named 'ssh' on te

### Copy scripts, configuration files and impulse responses

Before booting the Raspberry Pi for the first time, we'll need to prepare the image by copying the directory with this guide to the image, including the saved impulse responses to the prepared image.

## Configuring Raspbian

It's now time to boot the Raspberry Pi for the first time.

1. Connect network cable, and any other peripherals, such as your DAC.
2. Connect the Raspberry Pi to power
3. After booting, ssh into the machine:   `ssh pi@raspberrypi.local` - log in using the password 'raspberry'

### Update the Raspberry

    sudo apt-get update && sudo apt-get dist-upgrade

This may take a long time.  Just be patient and enjoy a cup of coffee

### Change the password

    sudo raspi-config

Select option 1 "Change User Password Change password for the default user (pi)", and pick a secure password.  While your Pi won't be visible to the internet at large, this is still good practice.

### (Optionally) change the hostname

While still in the raspi-config application, you may want to change the hostname to something more recognizable, using item 2: "Hostname             Set the visible name for this Pi on a network" option

### Set overclocking options

If you are running an older Raspberry Pi, such as the Model B or Model B+, you may want to overclock the Pi slightly.  Choose "Overclocking" (but take note of the warnings, as the author of this document will not be responsible for you damaging your Pi).  Using the option "Moderate" is sufficient.

If your Pi is a Pi 2, Pi 3 or Pi Zero, you will not need to overclock.

### Reboot and log back in

At this stage, you may want to reboot, so the hostname option takes effect.

### Installing, the easy way

SSH back into your Raspberry Pi, and execute the following commands:

    sudo -s
    mv /boot/brutepi .
    cd brutepi
    chmod +x install.sh
    ./install.sh

The installation script is interactive, and will ask you a few questions before commencing installation.  Follow on-screen instructions, and pay attention during installation.

After the installation, you can remove the repository:

    cd /home/brutepi
    sudo rm -rf brutepi

