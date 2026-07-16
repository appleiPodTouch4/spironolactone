# Spironolactone
# Origal repo https://github.com/Orangera1n/spironolactone
## Downgrade and dualboot function hasn't been tested,if it has some error occured,submit issue
This is a tool meant for booting dualboots, ssh ramdisks, and tether downgrades for now. Currently, it only supports generating ssh ramdisks and booting them.

Expansion in functionality (i.e. installing dualboots, jailbreaks, downgrades, etc) willl come at a later date. 

We also have a discord server at https://discord.gg/tXBqy3FRUP for updates and discussion

I will annunce updates over at https://x.com/_orangera1n and on the afformentioned discord

# What new
1. Auto install depends eg:venv pyusb pyserial pyusb capstone
2. Add color text
3. Add x86 Linux and x86 macOS support
4. Extrat ios version and buildid from BuildManifest.plist

# Important information
1. This tool is in VERY early stages of development, meaning that various functionailites might not be implemented or are otherwise buggy.
2. By using this tool, you will almost certainly wiping the device, back up any data beforehand.
3. Only iOS 12.0-14.4.2 are supported for now due to iBoot patch issues for A12, and iOS 13.0-13.7 are supported for A13.
Do *not* ask for an ETA for new features or version support

# Prerequsites
1. A computer running macOS or Linux (Linux haven't been tested)
2. A usbliter8 compatible devices (A12, A13)
- Note that A12X/Z is not implemented due to lack of offsets, and S4/S5 will likely not be implemented due to tooling reasons and lack of demand.
- Note that A14+ is extremely unlikely to come in the future.
3. Common sense
4. An rp2350-based development board, I recommend the Waveshare RP2350A USB Mini

# Usage
1. Clone this repository: git clone https://github.com/appleiPodTouch4/spironolactone.git --recursive
2. cd spironolactone
3. To make a ramdisk, run ./makerd.sh (iOS version here)/(IPSW url here) + (ramdisk/dualboot/downgrade)
4. To boot a ramdisk, run ./spiro.sh boot (bootchain name)
5. To connect SSH,run ./spiro.sh ssh
6. To update the script,run ./spiro.sh update
6. To reboot device,run ./spiro.sh reboot

# Issues
1. Some linux distro is unsupport(iBoot64Patcher might crash)
2. Linux version does not currently support dual-booting(without devicetree_parse and devicetree_repack),waiting for update.

# Credits
- [libimobiledevice](https://github.com/libimobiledevice/libimobiledevice) for libirecovery and other tools
- [Duy Tran](https://github.com/AldazActivator) for devicetree-parse
- [Nathan](https://github.com/verygenericname) for [sshtars](https://github.com/verygenericname/sshtars/) and [SSHRD_Script](https://github.com/verygenericname/), which is going to be helpful for understanding how this works
- [Paradigm Shift](https://github.com/prdgmshift) for [usbliter8 Explot](https://github.com/prdgmshift/usbliter8) used in the tool
- [AldazActivation](https://github.com/AldazActivator) (apologises again for using something from an icloud bypass dev, but it does work and isn't malicous) for usbliter8_boot
- [tihmstar](https://github.com/tihmstar) for pzb/original iBoot64Patcher, and img4tool
- [xerub](https://github.com/xerub) for img4lib and restored_external in the ramdisk
- [Cryptic](https://github.com/Cryptiiiic) for iBoot64Patcher fork
- [opa334](https://github.com/opa334) for TrollStore
- [OpenAI](https://chat.openai.com/chat) (yes we do apologize, but it's not sploified code) for converting [kerneldiff](https://github.com/mcg29/kerneldiff) into [C](https://github.com/verygenericname/kerneldiff_C)
