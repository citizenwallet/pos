import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:scanner/state/scan/state.dart';
import 'package:scanner/utils/delay.dart';

class NfcOverlay extends StatefulWidget {
  final Function()? onCancel;

  const NfcOverlay({super.key, this.onCancel});

  @override
  NfcOverlayState createState() => NfcOverlayState();
}

class NfcOverlayState extends State<NfcOverlay>
    with SingleTickerProviderStateMixin {
  bool _nfcReading = false;
  bool _showReader = false;

  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      lowerBound: 0,
      upperBound: 1,
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void onNfcReadingChanged(bool value) async {
    if (value) {
      // Start reading
      await delay(const Duration(milliseconds: 250));
      setState(() {
        _showReader = true;
      });
    } else {
      // Stop reading
      _showReader = false;
    }
  }

  void handleCancel() {
    widget.onCancel?.call();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final nfcReading = context.watch<ScanState>().nfcReading;

    if (_nfcReading != nfcReading) {
      onNfcReadingChanged(nfcReading);
    }
    _nfcReading = nfcReading;

    if (!nfcReading) {
      return const SizedBox();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedOpacity(
        opacity: _showReader ? 1 : 0,
        duration: const Duration(milliseconds: 250),
        child: Container(
          width: width,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          color: Colors.black.withOpacity(0.5),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(
                      height: 20,
                    ),
                    if (Platform.isAndroid)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          SvgPicture.asset(
                            'assets/icons/contactless.svg',
                            semanticsLabel: 'contactless payment',
                            height: 200,
                            width: 200,
                            colorFilter: const ColorFilter.mode(
                              Colors.white,
                              BlendMode.srcIn,
                            ),
                          ),
                          AnimatedBuilder(
                            animation: _controller,
                            builder: (context, child) => Opacity(
                              opacity: (1 - _controller.view.value),
                              child: const Icon(
                                Icons.arrow_forward,
                                size: 60,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    if (!Platform.isAndroid)
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          AnimatedBuilder(
                            animation: _controller,
                            builder: (context, child) => Opacity(
                              opacity: (1 - _controller.view.value),
                              child: const Icon(
                                Icons.arrow_upward,
                                size: 60,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          SvgPicture.asset(
                            'assets/icons/contactless.svg',
                            semanticsLabel: 'contactless payment',
                            height: 200,
                            width: 200,
                            colorFilter: const ColorFilter.mode(
                              Colors.white,
                              BlendMode.srcIn,
                            ),
                          ),
                        ],
                      ),
                    const Text(
                      'Tap to scan',
                      style: TextStyle(fontSize: 48, color: Colors.white),
                    ),
                    const SizedBox(
                      height: 40,
                    ),
                    OutlinedButton.icon(
                      onPressed: handleCancel,
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Expanded(child: SizedBox()),
            ],
          ),
        ),
      ),
    );
  }
}
