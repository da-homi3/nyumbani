import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:nyumbasearch/core/config/app_config.dart';

/// Loads a live NyumbaSearch path for marketing/legal visual parity.
class SiteContentPage extends StatefulWidget {
  const SiteContentPage({
    super.key,
    required this.title,
    required this.path,
  });

  final String title;
  /// Website path beginning with `/`, e.g. `/privacy`.
  final String path;

  @override
  State<SiteContentPage> createState() => _SiteContentPageState();
}

class _SiteContentPageState extends State<SiteContentPage> {
  late final WebViewController _controller;
  var _loading = true;
  String? _error;

  Uri get _uri {
    final base = AppConfig.apiBaseUrl.replaceAll(RegExp(r'/+$'), '');
    return Uri.parse('$base${widget.path}');
  }

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) {
              setState(() {
                _loading = true;
                _error = null;
              });
            }
          },
          onPageFinished: (_) async {
            try {
              // Soften site chrome for in-app reading.
              await _controller.runJavaScript('''
                (function(){
                  var s=document.createElement('style');
                  s.innerHTML=[
                    'header,nav,[data-site-nav],.site-nav,.tenant-bottom-nav,footer [data-sticky]{display:none!important}',
                    'body{padding-top:12px!important;padding-bottom:24px!important;max-width:100%!important}',
                    'main,article,.prose{max-width:42rem!important;margin-left:auto!important;margin-right:auto!important}'
                  ].join('');
                  document.head.appendChild(s);
                  document.querySelectorAll('a[target=_blank]').forEach(function(a){a.removeAttribute('target');});
                })();
              ''');
            } catch (_) {}
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (err) {
            if (mounted) {
              setState(() {
                _loading = false;
                _error = err.description.isNotEmpty
                    ? err.description
                    : 'Could not load page.';
              });
            }
          },
        ),
      );
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    await _controller.loadRequest(_uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            tooltip: 'Reload',
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_error == null) WebViewWidget(controller: _controller),
          if (_error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(onPressed: _load, child: const Text('Retry')),
                  ],
                ),
              ),
            ),
          if (_loading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
