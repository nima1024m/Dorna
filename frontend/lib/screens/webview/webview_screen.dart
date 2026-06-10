import 'package:flutter/material.dart';

class WebViewScreen extends StatefulWidget {
  static const String routeName = '/webview';

  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> with WidgetsBindingObserver {
  // InAppWebViewController? webViewController;
  // bool isLoading = true;
  // double progress = 0;
  //
  // @override
  // void initState() {
  //   super.initState();
  //   WidgetsBinding.instance.addObserver(this);
  // }
  //
  // @override
  // void dispose() {
  //   WidgetsBinding.instance.removeObserver(this);
  //   super.dispose();
  // }
  //
  //
  // Future<bool> _handleBackButton() async {
  //   if (webViewController != null) {
  //     // Check if webview can go back
  //     final canGoBackValue = await webViewController!.canGoBack();
  //     if (canGoBackValue) {
  //       // If webview can go back, go back in webview history
  //       await webViewController!.goBack();
  //       return false; // Consume the back button event
  //     }
  //   }
  //   // If webview can't go back, navigate away from the screen
  //   Get.back();
  //   return true; // Consume the back button event
  // }
  //
  @override
  Widget build(BuildContext context) {
    return Container();
    // return WillPopScope(
    //   onWillPop: _handleBackButton,
    //   child: Scaffold(
    //     body: SafeArea(
    //       child: Column(
    //         children: [
    //           // const Padding(
    //           //   padding: EdgeInsets.symmetric(horizontal: 16),
    //           //   child: BackHeader(
    //           //     title: 'WebView',
    //           //   ),
    //           // ),
    //           if (progress < 1.0)
    //             LinearProgressIndicator(
    //               value: progress,
    //               backgroundColor: Colors.grey[300],
    //               valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
    //             ),
    //           Expanded(
    //             child: Stack(
    //               children: [
    //                 InAppWebView(
    //                   initialUrlRequest: URLRequest(
    //                     url: WebUri('https://thedorna.com/'),
    //                   ),
    //                   initialSettings: InAppWebViewSettings(
    //                     javaScriptEnabled: true,
    //                     useShouldOverrideUrlLoading: true,
    //                     mediaPlaybackRequiresUserGesture: false,
    //                     allowsInlineMediaPlayback: true,
    //                     iframeAllow: "camera; microphone",
    //                     iframeAllowFullscreen: true,
    //                     allowsBackForwardNavigationGestures: true,
    //                   ),
    //                   onWebViewCreated: (controller) {
    //                     webViewController = controller;
    //                   },
    //                   shouldOverrideUrlLoading: (controller, navigationAction) async {
    //                     return NavigationActionPolicy.ALLOW;
    //                   },
    //                   onLoadStart: (controller, url) {
    //                     setState(() {
    //                       isLoading = true;
    //                     });
    //                   },
    //                   onLoadStop: (controller, url) {
    //                     setState(() {
    //                       isLoading = false;
    //                     });
    //                   },
    //                   onProgressChanged: (controller, progress) {
    //                     setState(() {
    //                       this.progress = progress / 100;
    //                     });
    //                   },
    //                   onReceivedError: (controller, request, error) {
    //                     debugPrint('WebView error: ${error.description}');
    //                   },
    //                   onReceivedServerTrustAuthRequest: (controller, challenge) async {
    //                     return ServerTrustAuthResponse(
    //                       action: ServerTrustAuthResponseAction.PROCEED,
    //                     );
    //                   },
    //                   onPermissionRequest: (controller, permissionRequest) async {
    //                     return PermissionResponse(
    //                       action: PermissionResponseAction.GRANT,
    //                       resources: permissionRequest.resources,
    //                     );
    //                   },
    //                 ),
    //                 if (isLoading)
    //                   const Center(
    //                     child: CircularProgressIndicator(),
    //                   ),
    //               ],
    //             ),
    //           ),
    //         ],
    //       ),
    //     ),
    //   ),
    // );
  }
}

