### How I got the touchscreen to work properly

1. replaced the device setting `dtoverlay=vc4-kms-v3d` with `dtoverlay=vc4-fmks-v3d` in `/boot/firmware/config.txt`;
2. switched the display backend from Xwayland to X11 by going to the setting interface (`sudo raspi-config`) and then chose `Advanced Options > A6 X11`;
3. rebooted.

### How to set up a kiosk on a Raspberry Pi OS

`chromium --kiosk <url>`

If you spawn this process on a remote machine, you need to specify the touchscreen as the display by setting `DISPLAY=:0` in front of the command; that is, the command would be `DISPLAY=:0 chromium --kiosk <url>`