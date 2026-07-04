#!/bin/bash
cd "$(dirname "$0")"
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
print "Modified by appleipodtouch4"
print "Thanks Asahi Scarlett rse4"

if [ "$option" = boot ]; then
    if [[ -z $(command -v python3) ]]; then
        error "Please install python3 first"
        exit 1
    fi

    if [[ ! -f resources/usbliter8.txt || ( $(cat resources/usbliter8.txt) != "usbliter8_boot" && $(cat resources/usbliter8.txt) != "usbliter8ctl" ) ]]; then
        log "Select which program you want to boot"
        print "1.usbliter8_boot(without depends)"
        print "2.usbliter8ctl(dependencies need to be installed)"
        log "Enter 1 or 2"
        read onetwo
        if [[ -f resources/usbliter8.txt ]]; then
            rm resources/usbliter8.txt
        fi
        if [[ $onetwo == "1" ]]; then
            echo  usbliter8_boot > resources/usbliter8.txt
        elif [[ $onetwo == "2" ]]; then
            echo  usbliter8ctl > resources/usbliter8.txt
        else
            error "Enter 1 or 2"
        fi
    fi

    usbliter8=$(cat resources/usbliter8.txt)

    if [[ $usbliter8 == "usbliter8ctl" ]]; then
        if [[ ! -d .venv ]]; then
            log "Creat venv"
            python3 -m venv .venv
        fi

        log "Active venv"
        source .venv/bin/activate

        depends=("pyimg4" "pyserial" "pyusb" "capstone")
        log "Check depends"
        for pkg in "${depends[@]}"; do
            if ! python3 -m pip show "$pkg" > /dev/null 2>&1; then
                log "Installing $pkg"
                python3 -m pip install "$pkg"
                if ! python3 -m pip show "$pkg" > /dev/null 2>&1; then
                    error "Install $pkg failed, check your internet connection"
                    exit 1 
                fi
            fi
        done
    fi

    if [[ $(uname) == "Darwin" ]]; then
        if [[ ! -f "/opt/homebrew/lib/libusb-1.0.dylib" ]] && [[ ! -f "/usr/local/lib/libusb-1.0.dylib" ]]; then
            error "Install libusb first"
            log "Using command 'brew install libusb' "
            exit 1
        fi
    else
        if [[ -z $(command -v libusb) ]]; then
            error "Install libusb first"
            log "Using command 'sudo apt install libusb' "
            exit 1
        fi
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
        if [[ $usbliter8 == "usbliter8ctl" ]]; then
            python3 "$oscheck"/usbliter8ctl boot bootchain/"$bootchain"/iBoot.patched.bin
        else
            "$oscheck"/usbliter8_boot bootchain/"$bootchain"/iBoot.patched.bin
        fi
        sleep 4
        if [[ -f bootchain/"$bootchain"/logo.img4 ]]; then
            log "Loading logo!"
            "$oscheck"/irecovery -f bootchain/"$bootchain"/logo.img4
        fi
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
    print "[*] For accessing device with FileZilla, note the following:"
    print "    Host: sftp://127.0.0.1   User: root   Password: alpine   Port: 2222"
    print "[*] Mount filesystems (make sure ramdisk version is correct):"
    print "    /usr/bin/mount_filesystems(mount /mnt2 will cause SEP panic.)"
    print "    mount_apfs /dev/disks1s1 /mnt1"
    print "[*] Rename system snapshot:"
    print '    /usr/bin/snaputil -n "$(/usr/bin/snaputil -l /mnt1)" orig-fs /mnt1'
    print "[*] Erase device without updating:"
    print "    /usr/sbin/nvram oblit-inprogress=5"
    print "[*] Reboot:"
    print "    /sbin/reboot"
    print "[*] Remove Setup.app (up to 13.2.3 or 12.4.4; on 10.0+ the device must be erased afterwards, on 11.3+ also rename system snapshot):"
    print "    rm -rf /mnt1/Applications/Setup.app"
    "$oscheck"/iproxy 2222 22 > /dev/null 2>&1 &
    "$oscheck"/sshpass -p 'alpine' ssh -o StrictHostKeyChecking=no -p2222 root@localhost || true
    killall iproxy > /dev/null 2>&1 | true
    if [ "$(uname)" = 'Linux' ]; then
        sudo killall usbmuxd > /dev/null 2>&1 | true
    fi
    exit
elif [ "$option" = update ]; then
    log "Checking update"
    local_ver=$(git rev-parse --short HEAD)
    commit_info=$(curl -s "https://api.github.com/repos/appleiPodTouch4/spironolactone/commits?per_page=1" | "$oscheck"/jq -r '.[0]')
    sha=$(echo "$commit_info" | "$oscheck"/jq -r '.sha')
    latest=${sha:0:7}
    if [[ -z $local_ver || -z $latest ]]; then
        error "Unable get version message,please check internet connection"
        exit
    fi
    if [[ $local_ver == $latest ]]; then
        log "It is already the latest commit,no upgrade required"
    else
        log "Newest commit is $latest. Do you want to update?(enter yes or no)"
        read yesno
        if [[ $yesno == "yes" ]]; then
            if [[ -z $(command -v git) ]]; then
                error Please install git first
                exit
            fi
            git pull
            if [[ $(git rev-parse --short HEAD) == $latest ]]; then
                log "Update successfully,run ./spiro.sh again"
            else
                error "Update failed,please check internet connection"
                exit
            fi
        else
            exit
        fi
    fi
else
    print 'To boot, run the script as "./spiro.sh boot boardconfig-version-build"'
fi
