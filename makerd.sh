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
echo "Welcome to Spironolactone v0.1.1 (Build: "$BUILD-$BRANCH")!"
echo "Fix by appleipodtouch4"
#export keypagename="$2"
#export keypage="https://theapplewiki.com/api.php?action=parse&formatversion=2&page="$keypagename"&prop=wikitext&format=json"
#echo $keypage
#curl -A "SpironolactoneKeyFetch" -s -o ./firmwarekeys.json "$keypage"
cpid=$("$oscheck"/irecovery -q | grep CPID | sed 's/CPID: //')
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
    buildid=$(curl -sL "https://api.ipsw.me/v4/device/$deviceid?type=ipsw" | "$oscheck"/jq '.firmwares | .[] | select(.version=="'$1'")' | "$oscheck"/jq -s '.[0] | .buildid' --raw-output)
    version=$(curl -sL "https://api.ipsw.me/v4/device/$deviceid?type=ipsw" | "$oscheck"/jq '.firmwares | .[] | select(.version=="'$1'")' | "$oscheck"/jq -s '.[0] | .version' --raw-output)
else
    echo "Use ./makerd.sh [iOS version] or./makerd.sh [ipsw url]"
    exit
fi


if [[ -z $ipswurl ]]; then
    echo "Unable to get ipsw url"
    exit
fi
fwkeyjson=$option2
if [[ $(uname -m) == "arm64" ]] && [[ -z $fwkeyjson ]]; then
    echo "Please define the fwkey json"
    exit
fi

mkdir work
cd work
../"$oscheck"/pzb -g BuildManifest.plist "$ipswurl"

if [[ "$option1" == http* ]]; then
    version=$(plutil -extract "ProductVersion" xml1 -o - "BuildManifest.plist" | sed -n 's/<string>\(.*\)<\/string>/\1/p')
    buildid=$(plutil -extract "ProductBuildVersion" xml1 -o - "BuildManifest.plist" | sed -n 's/<string>\(.*\)<\/string>/\1/p')
fi

filedir="$boardconfig-$version-$buildid"
if [[ -d bootchain/$filedir ]] && [[ -f "bootchain/$filedir/ANE.img4" && -f "bootchain/$filedir/AOP.img4" && -f "bootchain/$filedir/AVE.img4" && -f "bootchain/$filedir/devicetree.img4" && -f "bootchain/$filedir/GFX.img4" && -f "bootchain/$filedir/iBoot.patched.bin" && -f "bootchain/$filedir/ISP.img4" && -f "bootchain/$filedir/kernelcache.img4" && -f "bootchain/$filedir/ramdisk.img4" && -f "bootchain/$filedir/SIO.img4" && -f "bootchain/$filedir/trustcache.img4" ]]; then
    echo "Ramdisk exist,use ./spiro.sh boot $filedir to boot ramdisk"
    exit
elif [[ -d bootchain/$filedir ]]; then
    rm -r bootchain/$filedir
fi

../"$oscheck"/pzb -g "$(/usr/bin/plutil -extract "BuildIdentities".0."Manifest"."AOP"."Info"."Path" xml1 -o - BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1)" "$ipswurl"
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
../"$oscheck"/pzb -g "$(/usr/bin/plutil -extract "BuildIdentities".$bmindex."Manifest"."AOP"."Info"."Path" xml1 -o - BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1)" "$ipswurl"
../"$oscheck"/pzb -g "$(/usr/bin/plutil -extract "BuildIdentities".$bmindex."Manifest"."ANE"."Info"."Path" xml1 -o - BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1)" "$ipswurl"
../"$oscheck"/pzb -g "$(/usr/bin/plutil -extract "BuildIdentities".$bmindex."Manifest"."AVE"."Info"."Path" xml1 -o - BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1)" "$ipswurl"
../"$oscheck"/pzb -g "$(/usr/bin/plutil -extract "BuildIdentities".$bmindex."Manifest"."GFX"."Info"."Path" xml1 -o - BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1)" "$ipswurl"
../"$oscheck"/pzb -g "$(/usr/bin/plutil -extract "BuildIdentities".$bmindex."Manifest"."ISP"."Info"."Path" xml1 -o - BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1)" "$ipswurl"
../"$oscheck"/pzb -g "$(/usr/bin/plutil -extract "BuildIdentities".$bmindex."Manifest"."SIO"."Info"."Path" xml1 -o - BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1)" "$ipswurl"
../"$oscheck"/pzb -g "$(/usr/bin/plutil -extract "BuildIdentities".0."Manifest"."RestoreRamDisk"."Info"."Path" xml1 -o - BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1)" "$ipswurl"
../"$oscheck"/pzb -g Firmware/"$(/usr/bin/plutil -extract "BuildIdentities".0."Manifest"."RestoreRamDisk"."Info"."Path" xml1 -o - BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1)".trustcache "$ipswurl"
../"$oscheck"/pzb -g "$(awk "/""${replace}""/{x=1}x&&/kernelcache.release/{print;exit}" BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" "$ipswurl"
cd ..
if [[ $(uname -m) == "arm64" ]]; then
    iv=$(cat $fwkeyjson | "$oscheck"/jq -r 'first(.. | objects | select(has("iv")) | .iv)' | tr -d '"[]\n')
    key=$(cat $fwkeyjson | "$oscheck"/jq -r 'first(.. | objects | select(has("key")) | .key)' | tr -d '"[]\n')
    iv=${iv:2}
    key=${key:2}
    ivkey=$iv$key
else
    ivkey=$("$oscheck"/gfk ibec $deviceid $buildid $version)
    iv=${ivkey:0:32}
    key=${ivkey:32} 
    echo $ivkey
fi

if [[ -z $ivkey ]] || [[ $ivkey == "unable to find ivkey" ]]; then
    echo "Unable to get firmware key,you can define ivkey here"
    echo "You can go to https://theapplewiki.com/wiki/Firmware_Keys to find ivkey"
    echo "Enter iv"
    read iv
    echo "Enter key"
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

"$oscheck"/img4 -i work/"$(/usr/bin/plutil -extract "BuildIdentities".0."Manifest"."RestoreRamDisk"."Info"."Path" xml1 -o - work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1)" -o work/ramdisk.dmg
hdiutil resize -size 210MB work/ramdisk.dmg
hdiutil attach -mountpoint /tmp/SpironolactoneRD work/ramdisk.dmg -owners off
"$oscheck"/gtar -x --no-overwrite-dir -f resources/ssh.tar.gz -C /tmp/SpironolactoneRD/
hdiutil detach -force /tmp/SpironolactoneRD
hdiutil resize -sectors min work/ramdisk.dmg
"$oscheck"/img4 -i work/"$(/usr/bin/plutil -extract "BuildIdentities".0."Manifest"."RestoreRamDisk"."Info"."Path" xml1 -o - work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1)".trustcache -o work/trustcache.bin
mkdir work/sshtar
$oscheck/gtar -x --no-overwrite-dir -f resources/ssh.tar.gz -C work/sshtar
$oscheck/trustcache append work/trustcache.bin $(cat resources/sshtarlist.txt)
mkdir -p bootchain/$boardconfig-$version-$buildid
$oscheck/img4 -i work/DeviceTree.$boardconfig.im4p -o bootchain/$filedir/devicetree.img4 -T rdtr -M resources/IM4M_$cpid
$oscheck/img4 -i work/trustcache.bin -o bootchain/$filedir/trustcache.img4 -A -T rtsc -M resources/IM4M_$cpid
$oscheck/img4 -i work/ramdisk.dmg -o bootchain/$filedir/ramdisk.img4 -A -T rdsk -M resources/IM4M_$cpid
$oscheck/img4 -i work/"$(awk "/""${replace}""/{x=1}x&&/kernelcache.release/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" bootchain/$filedir/kernelcache.img4 -T rkrn -M resources/IM4M_$cpid
"$oscheck"/img4 -i work/"$(/usr/bin/plutil -extract "BuildIdentities".$bmindex."Manifest"."AOP"."Info"."Path" xml1 -o - work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1 |  cut -d'/' -f3-)" -o bootchain/$filedir/AOP.img4 -M resources/IM4M_$cpid
"$oscheck"/img4 -i work/"$(/usr/bin/plutil -extract "BuildIdentities".$bmindex."Manifest"."ANE"."Info"."Path" xml1 -o - work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1 |  cut -d'/' -f3-)" -o bootchain/$filedir/ANE.img4 -M resources/IM4M_$cpid
"$oscheck"/img4 -i work/"$(/usr/bin/plutil -extract "BuildIdentities".$bmindex."Manifest"."AVE"."Info"."Path" xml1 -o - work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1 |  cut -d'/' -f3-)" -o bootchain/$filedir/AVE.img4 -M resources/IM4M_$cpid
"$oscheck"/img4 -i work/"$(/usr/bin/plutil -extract "BuildIdentities".$bmindex."Manifest"."ISP"."Info"."Path" xml1 -o - work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1 |  cut -d'/' -f3-)" -o bootchain/$filedir/ISP.img4 -M resources/IM4M_$cpid
"$oscheck"/img4 -i work/"$(/usr/bin/plutil -extract "BuildIdentities".$bmindex."Manifest"."GFX"."Info"."Path" xml1 -o - work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1 |  cut -d'/' -f3-)" -o bootchain/$filedir/GFX.img4 -M resources/IM4M_$cpid
"$oscheck"/img4 -i work/"$(/usr/bin/plutil -extract "BuildIdentities".$bmindex."Manifest"."SIO"."Info"."Path" xml1 -o - work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1 |  cut -d'/' -f2-)" -o bootchain/$filedir/SIO.img4 -M resources/IM4M_$cpid
#"$oscheck"/ibootim resources/logo.ibootim work/logo.raw
#"$oscheck"/img4 -i work/logo.raw -o bootchain/$filedir/logo.img4 -M resources/IM4M_$cpid -T rlgo
touch bootchain/$filedir/.ramdisk


cp work/iBoot.patched bootchain/$filedir/iBoot.patched.bin

if [[ -f "bootchain/$filedir/ANE.img4" && -f "bootchain/$filedir/AOP.img4" && -f "bootchain/$filedir/AVE.img4" && -f "bootchain/$filedir/devicetree.img4" && -f "bootchain/$filedir/GFX.img4" && -f "bootchain/$filedir/iBoot.patched.bin" && -f "bootchain/$filedir/ISP.img4" && -f "bootchain/$filedir/kernelcache.img4" && -f "bootchain/$filedir/ramdisk.img4" && -f "bootchain/$filedir/SIO.img4" && -f "bootchain/$filedir/trustcache.img4" ]]; then
    echo 'To boot, run ./spiro.sh boot '"$filedir"
else
    echo "Some files cannot find,check logs"
    rm -r bootchain/$filedir
fi

read -s
rm -r work
