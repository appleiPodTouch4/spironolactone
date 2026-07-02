#!/bin/bash
oscheck=$(uname)/$(uname -m)
option=$1
bootchain=$2
BUILD=Spironolactone-10.1
BRANCH=$(git branch --show-current)
echo "Welcome to Spironolactone v0.1.1 (Build: "$BUILD-$BRANCH")!"
echo "Fix by appleipodtouch4"

if [ "$option" = boot ]; then
    if [[ -z $(command -v python3) ]]; then
        echo "Please install python3 first"
        exit 1
    fi

    if [[ ! -d .venv ]]; then
        echo "Creat venv"
        python3 -m venv .venv
    fi

    echo "Active venv"
    source .venv/bin/activate

    if [[ ! -f "/opt/homebrew/lib/libusb-1.0.dylib" ]] && [[ ! -f "/usr/local/lib/libusb-1.0.dylib" ]]; then
        echo "Install libusb first"
        echo "Using command 'brew install libusb' "
    fi

    if [[ -z $(command -v pyimg4) ]]; then
        python3 -m pip install pyusb
        python3 -m pip install pyimg4
        python3 -m pip install pyserial
        python3 -m pip install capstone
    fi
    if [ -n "$bootchain" ]; then
        sleep 3
        device_pwnd="$("$oscheck"/irecovery -q | grep "PWND" | cut -c 7-)"
        if [ -z "$device_pwnd" ]; then
            echo "Please use RP2350 to enter pwnDFU mode first!"
            exit
        else
            echo "[*] Pwned: "$device_pwnd""
        fi
        echo "Loading iBoot!"
        python3 "$oscheck"/usbliter8ctl boot bootchain/"$bootchain"/iBoot.patched.bin
        sleep 4
        #"$oscheck"/irecovery -f bootchain/"$bootchain"/logo.img4
        "$oscheck"/irecovery -c "setpicture 0x1"
        echo "Loading Devicetree!"
        "$oscheck"/irecovery -f bootchain/"$bootchain"/devicetree.img4
        "$oscheck"/irecovery -c "devicetree"
        if [ -e bootchain/"$bootchain"/.ramdisk ]; then
            echo "Loading Ramdisk!"
            "$oscheck"/irecovery -f bootchain/"$bootchain"/ramdisk.img4
            sleep 2
            "$oscheck"/irecovery -c ramdisk
        fi
        echo "Loading trustcache!"
        "$oscheck"/irecovery -f bootchain/"$bootchain"/trustcache.img4
        "$oscheck"/irecovery -c "firmware"
        echo "Loading AOP!"
        "$oscheck"/irecovery -f bootchain/"$bootchain"/AOP.img4
        "$oscheck"/irecovery -c "firmware"
        echo "Loading ANE!"
        "$oscheck"/irecovery -f bootchain/"$bootchain"/ANE.img4
        "$oscheck"/irecovery -c "firmware"
        echo "Loading AVE!"
        "$oscheck"/irecovery -f bootchain/"$bootchain"/AVE.img4
        "$oscheck"/irecovery -c "firmware"
        echo "Loading ISP!"
        "$oscheck"/irecovery -f bootchain/"$bootchain"/ISP.img4
        "$oscheck"/irecovery -c "firmware"
        echo "Loading GFX!"
        "$oscheck"/irecovery -f bootchain/"$bootchain"/GFX.img4
        "$oscheck"/irecovery -c "firmware"
        echo "Loading SIO!"
        "$oscheck"/irecovery -f bootchain/"$bootchain"/SIO.img4
        "$oscheck"/irecovery -c "firmware"
        echo "Loading and Booting Kernel!"
        "$oscheck"/irecovery -f bootchain/"$bootchain"/kernelcache.img4
        "$oscheck"/irecovery -c "bootx"
        echo "Done,use ./spiro.sh ssh to SSH into device"
    else
        echo 'To boot, you need to provide a "boardconfig-version-build" combination with your "./spiro.sh boot" commnad'
    fi
elif [ "$option" = ssh ]; then
    if [ "$(uname)" = 'Linux' ]; then
        sudo systemctl stop usbmuxd > /dev/null 2>&1 | true
        sudo killall usbmuxd > /dev/null 2>&1 | true
        sleep .1
        sudo usbmuxd -pf > /dev/null 2>&1 &
        sleep .1
    fi
    "$oscheck"/iproxy 2222 22 > /dev/null 2>&1 &
    "$oscheck"/sshpass -p 'alpine' ssh -o StrictHostKeyChecking=no -p2222 root@localhost || true
    killall iproxy > /dev/null 2>&1 | true
    if [ "$(uname)" = 'Linux' ]; then
        sudo killall usbmuxd > /dev/null 2>&1 | true
    fi
    exit
else
    echo 'To boot, run the script as "./spiro.sh boot boardconfig-version-build"'
fi
