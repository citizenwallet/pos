# Intro
Mobile app that serves as a Point of Sale application/Kiosk for our NFC wallets. 
The app provides "tap to pay" and "tap to top-up" functionality for our NFC wallets.

https://citizenwallet.notion.site/Kiosk-manual-1d5b408be10b446b90ed5e53978dd02e

## Standalone kiosk hardware I: 

https://www.notion.so/citizenwallet/Citizen-wallet-POS-hardware-58a038ce3e234e67827b8612d1805fb7?pvs=4#228a3f65e4ec4e1ca85ac28f61f39cb4

## Standalone kiosk hardware II: Fablab/RPi

https://www.notion.so/citizenwallet/Citizen-wallet-POS-hardware-58a038ce3e234e67827b8612d1805fb7?pvs=4#457ca3692a344d148de615346a7af2d2

## Getting Started

This project is a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## RPi build

This build uses the flutter-pi embedder https://github.com/ardera/flutter-pi 
Related code here https://github.com/chuck-h/rpi-kiosk/tree/flutter 

```
flutterpi_tool build --release
scp -r ./build/flutter_assets/ <your_rpi_address>:/home/pie/rpi-kiosk/pos
```

