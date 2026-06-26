# Spironolactone
This is a tool meant for booting dualboots, ssh ramdisks, and tether downgrades for now.

Expansion in functionality (i.e. installing dualboots, jailbreaks, downgrades, etc) willl come at a later date. 
# Important information
1. This tool is in VERY early stages of development, meaning that various functionailites might not be implemented or are otherwise buggy.
2. By using this tool, you will almost certainly wiping the device, back up any data beforehand.
3. This tool, for iOS 12 atleast, has all the seprmvr64 restrictions, meaning that you should not use it for a main device.

Do *not* ask for an ETA for this project.
# Prerequsites
1. A computer running macOS (Linux is untested, but is likely easy to implement, Windows is *very* unlikely)
2. A usbliter8 compatible devices (A12, A13)
- Note that A12X/Z is not implemented due to lack of offsets, and S4/S5 will likely not be implemented due to tooling reasons and lack of demand.
3. Common sense
4. An rp2350-based development board, I recommend the Waveshare RP2350A USB Mini

# Credits
- [libimobiledevice](https://github.com/libimobiledevice/libimobiledevice) for libirecovery and other tools
- [Nathan](https://github.com/verygenericname) for [sshtars](https://github.com/verygenericname/sshtars/) and [SSHRD_Script](https://github.com/verygenericname/sshtars/), which is going to be helpful for understanding how this works
- [Paradigm Shift](https://github.com/prdgmshift) for [usbliter8 Explot](https://github.com/prdgmshift/usbliter8) used in the tool
- [tihmstar](https://github.com/tihmstar) for pzb/original iBoot64Patcher, and img4tool
- [xerub](https://github.com/xerub) for img4lib and restored_external in the ramdisk
- [Cryptic](https://github.com/Cryptiiiic) for iBoot64Patcher fork
- [opa334](https://github.com/opa334) for TrollStore
- [OpenAI](https://chat.openai.com/chat) (yes we do apologize, but it's not sploified code) for converting [kerneldiff](https://github.com/mcg29/kerneldiff) into [C](https://github.com/verygenericname/kerneldiff_C)
