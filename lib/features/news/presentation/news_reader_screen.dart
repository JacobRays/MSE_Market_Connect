import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class NewsReaderScreen extends StatefulWidget {
  final String title;
  final String url;
  const NewsReaderScreen({super.key, required this.title, required this.url});

  @override
  State<NewsReaderScreen> createState() => _NewsReaderScreenState();
}

class _NewsReaderScreenState extends State<NewsReaderScreen> {
  late final WebViewController _controller;
  int _progress = 0;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(onProgress: (p) => setState(() => _progress = p)),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    // WebView is mobile-only; for web we just open external.
    if (kIsWeb) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: Center(
          child: ElevatedButton(
            onPressed: () => launchUrl(Uri.parse(widget.url)),
            child: const Text('Open article'),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'Open in browser',
            onPressed: () => launchUrl(Uri.parse(widget.url)),
            icon: const Icon(Icons.open_in_new),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_progress < 100)
            LinearProgressIndicator(value: _progress / 100.0, minHeight: 2),
          Expanded(child: WebViewWidget(controller: _controller)),
        ],
      ),
    );
  }
}
