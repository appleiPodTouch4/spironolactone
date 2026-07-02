#!/bin/bash
#export ipswurl="$1"
if [[ $EUID != 0 ]]; then
    echo "Enter your user password"
    sudo /bin/bash "$0" "$@"
    exit $?
fi
if [[ -d work ]]; then
    rm -r work
fi
oscheck=$(uname)/$(uname -m)
BUILD=Spironolactone-10.1
BRANCH=$(git branch --show-current)
chmod +x "$oscheck"/*

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

ERR_HANDLER () {
    [ $? -eq 0 ] && exit
    error "An error occurred"
    killall iproxy > /dev/null 2>&1 | true
    if [ "$(uname)" = 'Linux' ]; then
        sudo killall usbmuxd > /dev/null 2>&1 | true
    fi
}

trap ERR_HANDLER EXIT

print "Welcome to Spironolactone v0.1.2 (Build: "$BUILD-$BRANCH")!"
print "Fix by appleipodtouch4"
print "Thanks Asahi Scarlett rse4"

#export keypagename="$2"
#export keypage="https://theapplewiki.com/api.php?action=parse&formatversion=2&page="$keypagename"&prop=wikitext&format=json"
#echo $keypage
#curl -A "SpironolactoneKeyFetch" -s -o ./firmwarekeys.json "$keypage"
export option1="$1"
export option2="$2"
if [[ "$option1" == http* ]]; then
    ipswurl="$option1"
    boardconfig=$("$oscheck"/irecovery -q | grep MODEL | sed 's/MODEL: //')
    replace=$("$oscheck"/irecovery -q | grep MODEL | sed 's/MODEL: //')
    deviceid=$("$oscheck"/irecovery -q | grep PRODUCT | sed 's/PRODUCT: //')

elif [[ "$option1" =~ ^[0-9.]+$ ]]; then
    boardconfig=$("$oscheck"/irecovery -q | grep MODEL | sed 's/MODEL: //')
    replace=$("$oscheck"/irecovery -q | grep MODEL | sed 's/MODEL: //')
    deviceid=$("$oscheck"/irecovery -q | grep PRODUCT | sed 's/PRODUCT: //')
    ipswurl=$(curl -sL "https://api.ipsw.me/v4/device/$deviceid?type=ipsw" | "$oscheck"/jq '.firmwares | .[] | select(.version=="'$1'")' | "$oscheck"/jq -s '.[0] | .url' --raw-output)
else
    log "Use ./makerd.sh [iOS version] or ./makerd.sh [ipsw url]"
    exit
fi

cpid=$("$oscheck"/irecovery -q | grep CPID | sed 's/CPID: //')


if [[ -z $ipswurl ]]; then
    error "Unable to get ipsw url"
    exit
fi
fwkeyjson=$option2
if [[ $(uname -m) == "arm64" ]] && [[ -z $fwkeyjson ]]; then
    error "Please define the fwkey json"
    exit
fi

mkdir work
cd work
../"$oscheck"/pzb -g BuildManifest.plist "$ipswurl"


if [[ "$option1" == http* ]]; then
    if [ "$(uname)" = 'Darwin' ]; then
        version=$(/usr/bin/plutil -extract "ProductVersion" xml1 -o - "BuildManifest.plist" | sed -n 's/<string>\(.*\)<\/string>/\1/p')
        buildid=$(/usr/bin/plutil -extract "ProductBuildVersion" xml1 -o - "BuildManifest.plist" | sed -n 's/<string>\(.*\)<\/string>/\1/p')
    else
        version=$(../"$oscheck"/PlistBuddy -c "Print :ProductVersion" "BuildManifest.plist" | tr -d '"')
        buildid=$(../"$oscheck"/PlistBuddy -c "Print :ProductBuildVersion" "BuildManifest.plist" | tr -d '"')
    fi
else
    #dowmload tmp.json instead
    #buildid=$(curl -sL "https://api.ipsw.me/v4/device/$deviceid?type=ipsw" | ../"$oscheck"/jq '.firmwares | .[] | select(.version=="'$1'")' | ../"$oscheck"/jq -s '.[0] | .buildid' --raw-output)
    #version=$(curl -sL "https://api.ipsw.me/v4/device/$deviceid?type=ipsw" | ../"$oscheck"/jq '.firmwares | .[] | select(.version=="'$1'")' | ../"$oscheck"/jq -s '.[0] | .version' --raw-output)
    curl -s -L "https://api.ipsw.me/v4/device/$deviceid?type=ipsw" -o tmp.json
    buildid=$(../"$oscheck"/jq -r --arg ver "$1" '.firmwares[] | select(.version == $ver) | .buildid' tmp.json | head -n 1)
    version=$(../"$oscheck"/jq -r --arg ver "$1" '.firmwares[] | select(.version == $ver) | .version' tmp.json | head -n 1)
fi

major_ver=$(echo "$version" | cut -d. -f1)
minor_ver=$(echo "$version" | cut -d. -f2)
nano_ver=$(echo "$version" | cut -d. -f3)

if [[ $cpid == "0x8020" ]]; then
    if ! (( major_ver == 12 || major_ver == 13 || (major_ver == 14 && minor_ver < 4) || (major_ver == 14 && minor_ver == 4 && nano_ver <= 2) )); then
        error "iOS $version is not supported"
        exit 1
    fi
elif [[ $cpid == "0x8030" ]]; then
    if ! (( major_ver == 13 && minor_ver <= 7 )); then
        error "iOS $version is not supported"
        exit 1
    fi
else
    error "Support A12 and A13 devices only"
    exit 1
fi

filedir="$boardconfig-$version-$buildid"
log $filedir
pause
if [[ -d ../bootchain/$filedir ]] && [[ -f ../"bootchain/$filedir/ANE.img4" && -f ../"bootchain/$filedir/AOP.img4" && -f ../"bootchain/$filedir/AVE.img4" && -f ../"bootchain/$filedir/devicetree.img4" && -f ../"bootchain/$filedir/GFX.img4" && -f ../"bootchain/$filedir/iBoot.patched.bin" && -f ../"bootchain/$filedir/ISP.img4" && -f ../"bootchain/$filedir/kernelcache.img4" && -f ../"bootchain/$filedir/ramdisk.img4" && -f ../"bootchain/$filedir/SIO.img4" && -f ../"bootchain/$filedir/trustcache.img4" ]]; then
    print "Ramdisk exist,use ./spiro.sh boot $filedir to boot ramdisk"
    exit
elif [[ -d ../bootchain/$filedir ]]; then
    rm -r ../bootchain/$filedir
fi

if [ "$(uname)" = 'Darwin' ]; then
    ../"$oscheck"/pzb -g "$(/usr/bin/plutil -extract "BuildIdentities".0."Manifest"."AOP"."Info"."Path" xml1 -o - BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1)" "$ipswurl"
else
    ../"$oscheck"/pzb -g "$(../"$oscheck"/PlistBuddy BuildManifest.plist -c "Print BuildIdentities:0:Manifest:AOP:Info:Path" | sed 's/^"//; s/"$//')" "$ipswurl"
fi

aopfilenametest=$(ls aop*)
bmindex=0
if [[ "$aopfilenametest" == *11* && "$cpid" == "0x8030" ]]; then
    bmindex=3
elif [[ "$aopfilenametest" == *12* && "$cpid" == "0x8020" ]]; then
    bmindex=2
else
:
fi
#echo "$bmindex"
if [[ "$boardconfig" == n104ap ]]; then
    ../"$oscheck"/pzb -g Firmware/dfu/iBEC.n104.RELEASE.im4p "$ipswurl"
else
    ../"$oscheck"/pzb -g "$(awk "/""${replace}""/{x=1}x&&/iBEC[.]/{print;exit}" BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" "$ipswurl"
fi
../"$oscheck"/pzb -g "$(awk "/""${replace}""/{x=1}x&&/DeviceTree[.]/{print;exit}" BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" "$ipswurl"

if [ "$(uname)" = 'Darwin' ]; then
    ../"$oscheck"/pzb -g "$(/usr/bin/plutil -extract "BuildIdentities".$bmindex."Manifest"."AOP"."Info"."Path" xml1 -o - BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1)" "$ipswurl"
    ../"$oscheck"/pzb -g "$(/usr/bin/plutil -extract "BuildIdentities".$bmindex."Manifest"."ANE"."Info"."Path" xml1 -o - BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1)" "$ipswurl"
    ../"$oscheck"/pzb -g "$(/usr/bin/plutil -extract "BuildIdentities".$bmindex."Manifest"."AVE"."Info"."Path" xml1 -o - BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1)" "$ipswurl"
    ../"$oscheck"/pzb -g "$(/usr/bin/plutil -extract "BuildIdentities".$bmindex."Manifest"."GFX"."Info"."Path" xml1 -o - BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1)" "$ipswurl"
    ../"$oscheck"/pzb -g "$(/usr/bin/plutil -extract "BuildIdentities".$bmindex."Manifest"."ISP"."Info"."Path" xml1 -o - BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1)" "$ipswurl"
    ../"$oscheck"/pzb -g "$(/usr/bin/plutil -extract "BuildIdentities".$bmindex."Manifest"."SIO"."Info"."Path" xml1 -o - BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1)" "$ipswurl"
    ../"$oscheck"/pzb -g "$(/usr/bin/plutil -extract "BuildIdentities".0."Manifest"."RestoreRamDisk"."Info"."Path" xml1 -o - BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1)" "$ipswurl"
    ../"$oscheck"/pzb -g Firmware/"$(/usr/bin/plutil -extract "BuildIdentities".0."Manifest"."RestoreRamDisk"."Info"."Path" xml1 -o - BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1)".trustcache "$ipswurl"
else
    ../"$oscheck"/pzb -g "$(../"$oscheck"/PlistBuddy BuildManifest.plist -c "Print BuildIdentities:0:Manifest:AOP:Info:Path" | sed 's/^"//; s/"$//')" "$ipswurl"
    ../"$oscheck"/pzb -g "$(../"$oscheck"/PlistBuddy BuildManifest.plist -c "Print BuildIdentities:0:Manifest:ANE:Info:Path" | sed 's/^"//; s/"$//')" "$ipswurl"
    ../"$oscheck"/pzb -g "$(../"$oscheck"/PlistBuddy BuildManifest.plist -c "Print BuildIdentities:0:Manifest:AVE:Info:Path" | sed 's/^"//; s/"$//')" "$ipswurl"
    ../"$oscheck"/pzb -g "$(../"$oscheck"/PlistBuddy BuildManifest.plist -c "Print BuildIdentities:0:Manifest:GFX:Info:Path" | sed 's/^"//; s/"$//')" "$ipswurl"
    ../"$oscheck"/pzb -g "$(../"$oscheck"/PlistBuddy BuildManifest.plist -c "Print BuildIdentities:0:Manifest:ISP:Info:Path" | sed 's/^"//; s/"$//')" "$ipswurl"
    ../"$oscheck"/pzb -g "$(../"$oscheck"/PlistBuddy BuildManifest.plist -c "Print BuildIdentities:0:Manifest:SIO:Info:Path" | sed 's/^"//; s/"$//')" "$ipswurl"
    ../"$oscheck"/pzb -g "$(../"$oscheck"/PlistBuddy BuildManifest.plist -c "Print BuildIdentities:0:Manifest:RestoreRamDisk:Info:Path" | sed 's/^"//; s/"$//')" "$ipswurl"
    ../"$oscheck"/pzb -g Firmware/"$(../"$oscheck"/PlistBuddy BuildManifest.plist -c "Print BuildIdentities:0:Manifest:RestoreRamDisk:Info:Path" | sed 's/^"//; s/"$//')".trustcache "$ipswurl"
fi

../"$oscheck"/pzb -g "$(awk "/""${replace}""/{x=1}x&&/kernelcache.release/{print;exit}" BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" "$ipswurl"
cd ..

if [[ $(uname -m) == "arm64" ]]; then
    iv=$(cat $fwkeyjson | "$oscheck"/jq -r 'first(.. | objects | select(has("iv")) | .iv)' | tr -d '"[]\n')
    key=$(cat $fwkeyjson | "$oscheck"/jq -r 'first(.. | objects | select(has("key")) | .key)' | tr -d '"[]\n')
    iv=${iv:2}
    key=${key:2}
    ivkey=$iv$key
else
    ivkey=$("$oscheck"/gfk ibss $deviceid $buildid $version)
    iv=${ivkey:0:32}
    key=${ivkey:32} 
    echo $ivkey
fi

if [[ -z $ivkey ]] || [[ $ivkey == "unable to find ivkey" ]]; then
    error "Unable to get firmware key,you can define ivkey here"
    log "You can go to https://theapplewiki.com/wiki/Firmware_Keys to find ivkey"
    log "Enter iv"
    read iv
    log "Enter key"
    read key
    ivkey=${iv}${key}
    echo $ivkey
fi

if [[ "$boardconfig" == n104ap ]]; then
    "$oscheck"/img4 -i work/iBEC.n104.RELEASE.im4p -o work/iBoot.bin -k "$ivkey"
else
    "$oscheck"/img4 -i work/"$(awk "/""${replace}""/{x=1}x&&/iBEC[.]/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | sed 's/Firmware[/]dfu[/]//')" -o work/iBoot.bin  -k "$ivkey"
fi
"$oscheck"/iBoot64patcher_cryptic work/iBoot.bin work/iBoot.prepatched
"$oscheck"/kairos work/iBoot.prepatched work/iBoot.patched -b "-v debug=0x2014e rd=md0 wdt=-1"

if [ "$(uname)" = 'Darwin' ]; then
    "$oscheck"/img4 -i work/"$(/usr/bin/plutil -extract "BuildIdentities".0."Manifest"."RestoreRamDisk"."Info"."Path" xml1 -o - work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1)" -o work/ramdisk.dmg
    hdiutil resize -size 210MB work/ramdisk.dmg
    hdiutil attach -mountpoint /tmp/SpironolactoneRD work/ramdisk.dmg -owners off
    "$oscheck"/gtar -x --no-overwrite-dir -f resources/ssh.tar.gz -C /tmp/SpironolactoneRD/
    hdiutil detach -force /tmp/SpironolactoneRD
    hdiutil resize -sectors min work/ramdisk.dmg
    "$oscheck"/img4 -i work/"$(/usr/bin/plutil -extract "BuildIdentities".0."Manifest"."RestoreRamDisk"."Info"."Path" xml1 -o - work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1)".trustcache -o work/trustcache.bin
else
    "$oscheck"/img4 -i work/"$("$oscheck"/PlistBuddy work/BuildManifest.plist -c "Print BuildIdentities:0:Manifest:RestoreRamDisk:Info:Path" | sed 's/^"//; s/"$//')" -o work/ramdisk.dmg
    "$oscheck"/hfsplus work/ramdisk.dmg grow 210000000 > /dev/null
    "$oscheck"/hfsplus work/ramdisk.dmg untar resources/ssh.tar > /dev/null
    "$oscheck"/img4 -i work/"$("$oscheck"/PlistBuddy work/BuildManifest.plist -c "Print BuildIdentities:0:Manifest:RestoreRamDisk:Info:Path" | sed 's/^"//; s/"$//')".trustcache -o work/trustcache.bin
fi

mkdir work/sshtar
$oscheck/gtar -x --no-overwrite-dir -f resources/ssh.tar.gz -C work/sshtar
$oscheck/trustcache append work/trustcache.bin $(cat resources/sshtarlist.txt)
mkdir -p bootchain/$boardconfig-$version-$buildid
$oscheck/img4 -i work/DeviceTree.$boardconfig.im4p -o bootchain/$filedir/devicetree.img4 -T rdtr -M resources/IM4M_$cpid
$oscheck/img4 -i work/trustcache.bin -o bootchain/$filedir/trustcache.img4 -A -T rtsc -M resources/IM4M_$cpid
$oscheck/img4 -i work/ramdisk.dmg -o bootchain/$filedir/ramdisk.img4 -A -T rdsk -M resources/IM4M_$cpid
$oscheck/img4 -i work/"$(awk "/""${replace}""/{x=1}x&&/kernelcache.release/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" bootchain/$filedir/kernelcache.img4 -T rkrn -M resources/IM4M_$cpid
if [ "$(uname)" = 'Darwin' ]; then
    "$oscheck"/img4 -i work/"$(/usr/bin/plutil -extract "BuildIdentities".$bmindex."Manifest"."AOP"."Info"."Path" xml1 -o - work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1 |  cut -d'/' -f3-)" -o bootchain/$filedir/AOP.img4 -M resources/IM4M_$cpid
    "$oscheck"/img4 -i work/"$(/usr/bin/plutil -extract "BuildIdentities".$bmindex."Manifest"."ANE"."Info"."Path" xml1 -o - work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1 |  cut -d'/' -f3-)" -o bootchain/$filedir/ANE.img4 -M resources/IM4M_$cpid
    "$oscheck"/img4 -i work/"$(/usr/bin/plutil -extract "BuildIdentities".$bmindex."Manifest"."AVE"."Info"."Path" xml1 -o - work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1 |  cut -d'/' -f3-)" -o bootchain/$filedir/AVE.img4 -M resources/IM4M_$cpid
    "$oscheck"/img4 -i work/"$(/usr/bin/plutil -extract "BuildIdentities".$bmindex."Manifest"."ISP"."Info"."Path" xml1 -o - work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1 |  cut -d'/' -f3-)" -o bootchain/$filedir/ISP.img4 -M resources/IM4M_$cpid
    "$oscheck"/img4 -i work/"$(/usr/bin/plutil -extract "BuildIdentities".$bmindex."Manifest"."GFX"."Info"."Path" xml1 -o - work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1 |  cut -d'/' -f3-)" -o bootchain/$filedir/GFX.img4 -M resources/IM4M_$cpid
    "$oscheck"/img4 -i work/"$(/usr/bin/plutil -extract "BuildIdentities".$bmindex."Manifest"."SIO"."Info"."Path" xml1 -o - work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1 |  cut -d'/' -f2-)" -o bootchain/$filedir/SIO.img4 -M resources/IM4M_$cpid
else
    "$oscheck"/img4 -i work/"$("$oscheck"/PlistBuddy work/BuildManifest.plist -c "Print BuildIdentities:0:Manifest:AOP:Info:Path" | sed -E 's#^.*Firmware/##; s#^.*AOP/##; s/^"//; s/"$//')" -o bootchain/$filedir/AOP.img4 -M resources/IM4M_$cpid
    "$oscheck"/img4 -i work/"$("$oscheck"/PlistBuddy work/BuildManifest.plist -c "Print BuildIdentities:0:Manifest:ANE:Info:Path" | sed -E 's#^.*Firmware/##; s#^.*ane/##; s/^"//; s/"$//')" -o bootchain/$filedir/ANE.img4 -M resources/IM4M_$cpid
    "$oscheck"/img4 -i work/"$("$oscheck"/PlistBuddy work/BuildManifest.plist -c "Print BuildIdentities:0:Manifest:AVE:Info:Path" | sed -E 's#^.*Firmware/##; s#^.*ave/##; s/^"//; s/"$//')" -o bootchain/$filedir/AVE.img4 -M resources/IM4M_$cpid
    "$oscheck"/img4 -i work/"$("$oscheck"/PlistBuddy work/BuildManifest.plist -c "Print BuildIdentities:0:Manifest:ISP:Info:Path" | sed -E 's#^.*Firmware/##; s#^.*isp_bni/##; s/^"//; s/"$//')" -o bootchain/$filedir/ISP.img4 -M resources/IM4M_$cpid
    "$oscheck"/img4 -i work/"$("$oscheck"/PlistBuddy work/BuildManifest.plist -c "Print BuildIdentities:0:Manifest:GFX:Info:Path" | sed -E 's#^.*Firmware/##; s#^.*agx/##; s/^"//; s/"$//')" -o bootchain/$filedir/GFX.img4 -M resources/IM4M_$cpid
    "$oscheck"/img4 -i work/"$("$oscheck"/PlistBuddy work/BuildManifest.plist -c "Print BuildIdentities:0:Manifest:SIO:Info:Path" | sed -E 's#^.*Firmware/##; s/^"//; s/"$//')" -o bootchain/$filedir/SIO.img4 -M resources/IM4M_$cpid
fi
touch bootchain/$filedir/.ramdisk


cp work/iBoot.patched bootchain/$filedir/iBoot.patched.bin

if [[ -f "bootchain/$filedir/ANE.img4" && -f "bootchain/$filedir/AOP.img4" && -f "bootchain/$filedir/AVE.img4" && -f "bootchain/$filedir/devicetree.img4" && -f "bootchain/$filedir/GFX.img4" && -f "bootchain/$filedir/iBoot.patched.bin" && -f "bootchain/$filedir/ISP.img4" && -f "bootchain/$filedir/kernelcache.img4" && -f "bootchain/$filedir/ramdisk.img4" && -f "bootchain/$filedir/SIO.img4" && -f "bootchain/$filedir/trustcache.img4" ]]; then
    print 'To boot, run ./spiro.sh boot '"$filedir"
else
    error "Some files cannot find,check logs"
    rm -r bootchain/$filedir
fi

pause

rm -r work
