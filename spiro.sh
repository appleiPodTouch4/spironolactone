#!/bin/bash
oscheck=$(uname)/$(uname -m)
option=$1
bootchain=$2
BUILD=Spironolactone-10.1
BRANCH=$(git branch --show-current)

TERM=xterm-256color
color_R=$(tput setaf 9)
color_G=$(tput setaf 10)
color_B=$(tput setaf 12)
color_Y=$(tput setaf 208)
color_N=$(tput sgr0)

print() {
    echo "${color_B}${1}${color_N}"
}

input() {
    echo "${color_Y}[Input] ${1}${color_N}"
}

log() {
    echo "${color_G}[Log] ${1}${color_N}"
}

warn() {
    echo "${color_Y}[WARNING] ${1}${color_N}"
}

error() {
    echo -e "${color_R}[Error] ${1}\n${color_Y}${*:2}${color_N}"
}

pause() {
    input "Press Enter/Return to continue (or press Ctrl+C to cancel)"
    read -s
}

print "Welcome to Spironolactone v0.1.2 (Build: "$BUILD-$BRANCH")!"
print "Fix by appleipodtouch4"
print "Thanks Asahi Scarlett rse4"

if [ "$option" = boot ]; then
    if [[ -z $(command -v python3) ]]; then
        error "Please install python3 first"
        exit 1
    fi

    if [[ ! -d .venv ]]; then
        log "Creat venv"
        python3 -m venv .venv
    fi

    log "Active venv"
    source .venv/bin/activate

    if [[ ! -f "/opt/homebrew/lib/libusb-1.0.dylib" ]] && [[ ! -f "/usr/local/lib/libusb-1.0.dylib" ]]; then
        error "Install libusb first"
        log "Using command 'brew install libusb' "
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
            error "Please use RP2350 to enter pwnDFU mode first!"
            exit
        else
            log "[*] Pwned: "$device_pwnd""
        fi
        log "Loading iBoot!"
        python3 "$oscheck"/usbliter8ctl boot bootchain/"$bootchain"/iBoot.patched.bin
        sleep 4
        #"$oscheck"/irecovery -f bootchain/"$bootchain"/logo.img4
        "$oscheck"/irecovery -c "setpicture 0x1"
        log "Loading Devicetree!"
        "$oscheck"/irecovery -f bootchain/"$bootchain"/devicetree.img4
        "$oscheck"/irecovery -c "devicetree"
        if [ -e bootchain/"$bootchain"/.ramdisk ]; then
            log "Loading Ramdisk!"
            "$oscheck"/irecovery -f bootchain/"$bootchain"/ramdisk.img4
            sleep 2
            "$oscheck"/irecovery -c ramdisk
        fi
        log "Loading trustcache!"
        "$oscheck"/irecovery -f bootchain/"$bootchain"/trustcache.img4
        "$oscheck"/irecovery -c "firmware"
        log "Loading AOP!"
        "$oscheck"/irecovery -f bootchain/"$bootchain"/AOP.img4
        "$oscheck"/irecovery -c "firmware"
        log "Loading ANE!"
        "$oscheck"/irecovery -f bootchain/"$bootchain"/ANE.img4
        "$oscheck"/irecovery -c "firmware"
        log "Loading AVE!"
        "$oscheck"/irecovery -f bootchain/"$bootchain"/AVE.img4
        "$oscheck"/irecovery -c "firmware"
        log "Loading ISP!"
        "$oscheck"/irecovery -f bootchain/"$bootchain"/ISP.img4
        "$oscheck"/irecovery -c "firmware"
        log "Loading GFX!"
        "$oscheck"/irecovery -f bootchain/"$bootchain"/GFX.img4
        "$oscheck"/irecovery -c "firmware"
        log "Loading SIO!"
        "$oscheck"/irecovery -f bootchain/"$bootchain"/SIO.img4
        "$oscheck"/irecovery -c "firmware"
        log "Loading and Booting Kernel!"
        "$oscheck"/irecovery -f bootchain/"$bootchain"/kernelcache.img4
        "$oscheck"/irecovery -c "bootx"
        log "Done,use ./spiro.sh ssh to SSH into device"
    else
        print 'To boot, you need to provide a "boardconfig-version-build" combination with your "./spiro.sh boot" commnad'
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
elif [ "$option" = update ]; then
    log Checking update
    local_ver=$(git rev-parse --short HEAD)
    commit_info=$(curl -s "https://api.github.com/repos/appleiPodTouch4/SSHRD_Script_32Bit/commits?per_page=1" | "$oscheck"/jq -r '.[0]')
    sha=$(echo "$commit_info" | "$oscheck"/jq -r '.sha')
    latest=${sha:0:7}
    if [[ -z $local_ver || -z $latest ]]; then
        error Unable get version message,please check internet connection
        exit
    fi
    if [[ $local_ver == $latest ]]; then
        log It is already the latest commit,no upgrade required
    else
        log "Newest commit is $latest. Do you want to update?(enter yes or no)"
        read yesno
        if [[ $yesno == "yes" ]]; then
            if [[ -z $(command -v git) ]]; then
                error Please install git first
                exit
            fi
            git fetch origin
            git reset --hard origin/main
            if [[ $(git rev-parse --short HEAD) == $latest ]]; then
                log Update successfully,run ./spiro.sh again
            else
                error Update failed,please check internet connection
                exit
            fi
        else
            exit
        fi
    fi
else
    print 'To boot, run the script as "./spiro.sh boot boardconfig-version-build"'
fi
