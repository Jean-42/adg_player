import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import '../models/queue_item.dart';
import '../theme.dart';
import 'youtube_player_widget.dart';

class EmbedPlayer extends StatefulWidget {
  final QueueItem? item;
  final bool fullscreen;
  const EmbedPlayer({super.key, this.item, this.fullscreen = false});
  @override
  State<EmbedPlayer> createState() => _EmbedPlayerState();
}

class _EmbedPlayerState extends State<EmbedPlayer> {
  WebViewController? _ctrl;
  bool _loading = true;
  String? _loadedItemId;

  @override
  void initState() {
    super.initState();
    if (widget.item != null && widget.item!.type != MediaType.youtube) {
      _load(widget.item!);
    }
  }

  @override
  void didUpdateWidget(EmbedPlayer old) {
    super.didUpdateWidget(old);
    final item = widget.item;
    if (item == null) {
      setState(() => _loadedItemId = null);
      return;
    }
    // YouTube videos are handled by YoutubePlayerWidget
    if (item.type == MediaType.youtube) {
      setState(() => _loadedItemId = null);
      return;
    }
    if (item.id != _loadedItemId) _load(item);
  }

  void _load(QueueItem item) {
    _loadedItemId = item.id;

    String baseUrl;
    String userAgent;
    switch (item.type) {
      case MediaType.vimeo:
        baseUrl = 'https://player.vimeo.com/';
        userAgent = '';
        break;
      case MediaType.dailymotion:
        baseUrl = 'https://geo.dailymotion.com/';
        userAgent = '';
        break;
      case MediaType.facebook:
        baseUrl = 'https://www.facebook.com/';
        userAgent = '';
        break;
      case MediaType.instagram:
        baseUrl = 'https://www.instagram.com/';
        userAgent = '';
        break;
      default:
        baseUrl = 'https://www.youtube.com/';
        userAgent = '';
    }

    final html = _buildHtml(item);

    final ctrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) {
          if (mounted) setState(() => _loading = true);
        },
        onPageFinished: (_) {
          if (mounted) setState(() => _loading = false);
        },
        onWebResourceError: (_) {
          if (mounted) setState(() => _loading = false);
        },
        onNavigationRequest: (_) => NavigationDecision.navigate,
      ))
      ..loadHtmlString(html, baseUrl: baseUrl);

    final platform = ctrl.platform;
    if (platform is AndroidWebViewController) {
      platform.setMediaPlaybackRequiresUserGesture(false);
      AndroidWebViewController.enableDebugging(false);
    }

    if (userAgent.isNotEmpty) {
      ctrl.setUserAgent(userAgent);
    }

    if (mounted) setState(() {
      _ctrl = ctrl;
      _loading = true;
    });
  }

  String _buildHtml(QueueItem item) {
    final src = item.embedUrl;
    final isFB = item.type == MediaType.facebook;
    final topPad = isFB ? 'padding-top:36px;' : '';

    return '''<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<meta name="referrer" content="no-referrer-when-downgrade">
<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no">
<style>
  *{margin:0;padding:0;box-sizing:border-box}
  html,body{width:100%;height:100%;background:#000;overflow:hidden;${topPad}}
  iframe{width:100%;height:100%;border:none;display:block}
</style>
</head>
<body>
<iframe
  src="$src"
  allow="autoplay; fullscreen; picture-in-picture; clipboard-write; encrypted-media; accelerometer; gyroscope"
  allowfullscreen
  referrerpolicy="no-referrer-when-downgrade"
  frameborder="0"
  scrolling="no">
</iframe>
</body>
</html>''';
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    if (item == null) return _placeholder();

    // YouTube videos use native player
    if (item.type == MediaType.youtube) {
      final id = _extractYoutubeId(item.url);
      if (id != null) {
        return YoutubePlayerWidget(
          videoId: id,
          title: item.title,
          subtitle: item.subtitle,
          fullscreen: widget.fullscreen,
        );
      }
    }

    final isFacebook = item.type == MediaType.facebook;

    return Stack(children: [
      if (_ctrl != null)
        WebViewWidget(controller: _ctrl!)
      else
        const ColoredBox(color: Colors.black),

      if (isFacebook)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _FacebookNotice(url: item.url, isReel: item.isPortraitVideo),
        ),

      if (_loading)
        Container(
          color: Colors.black87,
          alignment: Alignment.center,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                    color: AppColors.accent, strokeWidth: 2.5)),
            const SizedBox(height: 10),
            Text('Loading ${item.subtitle}…',
                style: const TextStyle(color: AppColors.text2, fontSize: 12)),
          ]),
        ),
    ]);
  }

  String? _extractYoutubeId(String url) {
    final patterns = [
      RegExp(
          r'(?:youtube\.com/(?:watch\?v=|shorts/|embed/)|youtu\.be/)([a-zA-Z0-9_-]{11})'),
      RegExp(r'^([a-zA-Z0-9_-]{11})$'),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(url);
      if (m != null) return m.group(1);
    }
    return null;
  }

  Widget _placeholder() => Container(
    color: AppColors.bg2,
    alignment: Alignment.center,
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
              color: AppColors.bg4, borderRadius: BorderRadius.circular(30)),
          child: const Icon(Icons.play_circle_outline,
              color: AppColors.accent2, size: 30)),
      const SizedBox(height: 12),
      const Text('No video loaded',
          style: TextStyle(color: AppColors.text3, fontSize: 13)),
    ]),
  );
}

class _FacebookNotice extends StatelessWidget {
  final String url;
  final bool isReel;
  const _FacebookNotice({required this.url, required this.isReel});

  @override
  Widget build(BuildContext context) => Container(
    height: 36,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: const BoxDecoration(
      color: AppColors.bg3,
      border: Border(bottom: BorderSide(color: AppColors.border)),
    ),
    child: Row(children: [
      const Icon(Icons.facebook, color: AppColors.blue, size: 14),
      const SizedBox(width: 6),
      Expanded(
          child: Text(
        isReel ? 'Facebook Reel — may need login' : 'Facebook — may need login',
        style: const TextStyle(color: AppColors.text2, fontSize: 11),
        overflow: TextOverflow.ellipsis,
      )),
      const SizedBox(width: 8),
      GestureDetector(
        onTap: () async {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
              color: AppColors.blue, borderRadius: BorderRadius.circular(14)),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.open_in_new, color: Colors.white, size: 11),
            SizedBox(width: 4),
            Text('Open',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    ]),
  );
}