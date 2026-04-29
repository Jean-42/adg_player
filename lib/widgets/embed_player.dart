import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import '../models/queue_item.dart';
import '../services/player_controller.dart';
import '../theme.dart';
import 'youtube_player_widget.dart';

class EmbedPlayer extends StatefulWidget {
  final QueueItem? item;
  const EmbedPlayer({super.key, this.item});
  @override
  State<EmbedPlayer> createState() => _EmbedPlayerState();
}

class _EmbedPlayerState extends State<EmbedPlayer> {
  WebViewController? _ctrl;
  bool _loading = true;
  String? _loadedItemId;
  Timer? _positionTimer;

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
    if (item == null || item.type == MediaType.youtube) {
      setState(() => _loadedItemId = null);
      return;
    }
    if (item.id != _loadedItemId) _load(item);
  }

  @override
  void dispose() {
    _positionTimer?.cancel();
    super.dispose();
  }

  void _startPositionTracking(QueueItem item) {
    _positionTimer?.cancel();
    _positionTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_ctrl == null || !mounted) return;
      _ctrl!.runJavaScriptReturningResult('window._lastPos || 0').then((r) {
        final secs = double.tryParse(r.toString()) ?? 0;
        if (secs > 5 && mounted) {
          context.read<PlayerController>().reportEmbedPosition(
              item.id, Duration(milliseconds: (secs * 1000).round()));
        }
      }).catchError((_) {});
    });
  }

  void _load(QueueItem item) {
    _positionTimer?.cancel();
    _loadedItemId = item.id;

    final resumeMs = context.read<PlayerController>()
        .getSavedPosition(item.id)?.inMilliseconds ?? 0;

    String baseUrl;
    switch (item.type) {
      case MediaType.vimeo:       baseUrl = 'https://player.vimeo.com/'; break;
      case MediaType.dailymotion: baseUrl = 'https://geo.dailymotion.com/'; break;
      case MediaType.facebook:    baseUrl = 'https://www.facebook.com/'; break;
      case MediaType.instagram:   baseUrl = 'https://www.instagram.com/'; break;
      default:                    baseUrl = 'https://www.youtube.com/'; break;
    }

    final ctrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..addJavaScriptChannel('PositionChannel',
          onMessageReceived: (msg) {
            final secs = double.tryParse(msg.message) ?? 0;
            if (secs > 5 && mounted) {
              context.read<PlayerController>().reportEmbedPosition(
                  item.id, Duration(milliseconds: (secs * 1000).round()));
            }
          })
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted:    (_) { if (mounted) setState(() => _loading = true); },
        onPageFinished:   (_) { if (mounted) { setState(() => _loading = false); _startPositionTracking(item); } },
        onWebResourceError: (_) { if (mounted) setState(() => _loading = false); },
        onNavigationRequest: (_) => NavigationDecision.navigate,
      ))
      ..loadHtmlString(_buildHtml(item, resumeMs), baseUrl: baseUrl);

    final platform = ctrl.platform;
    if (platform is AndroidWebViewController) {
      platform.setMediaPlaybackRequiresUserGesture(false);
      AndroidWebViewController.enableDebugging(false);
      // Allow rotation when the iframe triggers fullscreen (Dailymotion etc.)
      platform.setCustomWidgetCallbacks(
        onShowCustomWidget: (widget, onHideCustomWidget) {
          // Video entered native fullscreen — allow all orientations
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.portraitUp,
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ]);
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => Scaffold(
              backgroundColor: Colors.black,
              body: widget,
            ),
          )).then((_) => onHideCustomWidget());
        },
        onHideCustomWidget: () {
          // Exited fullscreen — restore portrait + UI
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.portraitUp,
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ]);
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        },
      );
    }

    if (mounted) setState(() { _ctrl = ctrl; _loading = true; });
  }

  String _buildHtml(QueueItem item, int resumeMs) {
    final src       = item.embedUrl;
    final portrait  = item.type == MediaType.facebook || item.type == MediaType.instagram;
    final resumeSecs = (resumeMs / 1000).floor();
    final isVimeo       = item.type == MediaType.vimeo;
    final isDailymotion = item.type == MediaType.dailymotion;

    final iframeStyle = portrait ? '''
  #container { display:flex; justify-content:center; align-items:center; width:100%; height:100%; background:#000; }
  .frame-wrap { position:relative; width:min(56.25vh,100%); aspect-ratio:9/16; max-height:100%; }
  iframe { position:absolute; top:0; left:0; width:100%; height:100%; border:none; }
''' : '''
  #container { display:flex; justify-content:center; align-items:center; width:100%; height:100%; background:#000; }
  .frame-wrap { width:100%; height:100%; position:relative; }
  iframe { position:absolute; top:0; left:0; width:100%; height:100%; border:none; }
''';

    String positionJs = '';
    if (isVimeo) {
      positionJs = '''<script>
var _lastPos=$resumeSecs, _seeked=false;
var iframe=document.getElementById('player');
window.addEventListener('message',function(e){
  var d=e.data; if(typeof d==='string'){try{d=JSON.parse(d);}catch(ex){return;}} if(!d||d.player!=='vimeo')return;
  if(d.event==='ready'){
    iframe.contentWindow.postMessage(JSON.stringify({method:'addEventListener',value:'timeupdate'}),'*');
    if($resumeSecs>5&&!_seeked){_seeked=true;iframe.contentWindow.postMessage(JSON.stringify({method:'setCurrentTime',value:$resumeSecs}),'*');}
  }
  if(d.event==='timeupdate'&&d.data){_lastPos=d.data.seconds||0;PositionChannel.postMessage(String(Math.floor(_lastPos)));}
});
setTimeout(function(){iframe.contentWindow.postMessage(JSON.stringify({method:'addEventListener',value:'ready'}),'*');},500);
</script>''';
    } else if (isDailymotion) {
      positionJs = '''<script>
var _lastPos=$resumeSecs, _seeked=false;
var iframe=document.getElementById('player');
window.addEventListener('message',function(e){
  var d=e.data; if(typeof d==='string'){try{d=JSON.parse(d);}catch(ex){return;}} if(!d)return;
  if(d.event==='apiready'){if($resumeSecs>5&&!_seeked){_seeked=true;iframe.contentWindow.postMessage(JSON.stringify({command:'seek',parameters:[$resumeSecs]}),'*');}}
  if(d.event==='timeupdate'&&typeof d.time==='number'){_lastPos=d.time;PositionChannel.postMessage(String(Math.floor(_lastPos)));}
});
</script>''';
    } else {
      // Facebook/Instagram: cross-origin, use wall-clock approximation
      positionJs = '''<script>
var _lastPos=$resumeSecs, _start=Date.now();
setInterval(function(){_lastPos=$resumeSecs+(Date.now()-_start)/1000;PositionChannel.postMessage(String(Math.floor(_lastPos)));},5000);
</script>''';
    }

    // Facebook video/embed needs referrer policy 'origin' to load correctly
    final referrerPolicy = item.type == MediaType.facebook
        ? 'origin'
        : 'no-referrer-when-downgrade';

    return '''<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<meta name="referrer" content="$referrerPolicy">
<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no">
<style>*{margin:0;padding:0;box-sizing:border-box}html,body{width:100%;height:100%;background:#000;overflow:hidden}$iframeStyle</style>
</head>
<body>
<div id="container"><div class="frame-wrap">
  <iframe id="player" src="$src"
    allow="autoplay; fullscreen; picture-in-picture; clipboard-write; encrypted-media; accelerometer; gyroscope"
    allowfullscreen referrerpolicy="$referrerPolicy" frameborder="0" scrolling="no">
  </iframe>
</div></div>
$positionJs
</body></html>''';
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    if (item == null) return _placeholder();

    if (item.type == MediaType.youtube) {
      final id = _extractYoutubeId(item.url);
      if (id != null) {
        return YoutubePlayerWidget(
            videoId: id, title: item.title, subtitle: item.subtitle);
      }
    }

    return Stack(children: [
      if (_ctrl != null) WebViewWidget(controller: _ctrl!)
      else const ColoredBox(color: Colors.black),

      if (item.type == MediaType.facebook)
        Positioned(
          top: 0, left: 0, right: 0,
          child: _FacebookNoticeBar(
            url: item.url,
            // Show whether we got the full player or fallback
            usingFallback: !item.embedUrl.contains('video/embed'),
          ),
        ),

      if (_loading)
        Container(
          color: Colors.black87,
          alignment: Alignment.center,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(width: 28, height: 28,
                child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2.5)),
            const SizedBox(height: 10),
            Text('Loading ${item.subtitle}…',
                style: const TextStyle(color: AppColors.text2, fontSize: 12)),
          ]),
        ),
    ]);
  }

  String? _extractYoutubeId(String url) {
    final patterns = [
      RegExp(r'(?:youtube\.com/(?:watch\?v=|shorts/|embed/)|youtu\.be/)([a-zA-Z0-9_-]{11})'),
      RegExp(r'^([a-zA-Z0-9_-]{11})$'),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(url); if (m != null) return m.group(1);
    }
    return null;
  }

  Widget _placeholder() => Container(
    color: AppColors.bg2,
    alignment: Alignment.center,
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 60, height: 60,
          decoration: BoxDecoration(color: AppColors.bg4, borderRadius: BorderRadius.circular(30)),
          child: const Icon(Icons.play_circle_outline, color: AppColors.accent2, size: 30)),
      const SizedBox(height: 12),
      const Text('No video loaded', style: TextStyle(color: AppColors.text3, fontSize: 13)),
    ]),
  );
}

class _FacebookNoticeBar extends StatelessWidget {
  final String url;
  final bool usingFallback;
  const _FacebookNoticeBar({required this.url, this.usingFallback = false});

  @override
  Widget build(BuildContext context) => Container(
    height: 36,
    padding: const EdgeInsets.symmetric(horizontal: 10),
    decoration: const BoxDecoration(
      color: AppColors.bg3,
      border: Border(bottom: BorderSide(color: AppColors.border)),
    ),
    child: Row(children: [
      const Icon(Icons.facebook, color: AppColors.blue, size: 14),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          usingFallback
              ? 'Facebook — no video ID found, limited controls'
              : 'Facebook — may need login',
          style: TextStyle(
              color: usingFallback ? AppColors.yellow : AppColors.text2,
              fontSize: 11),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      const SizedBox(width: 6),
      GestureDetector(
        onTap: () async {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: AppColors.blue, borderRadius: BorderRadius.circular(12)),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.open_in_new, color: Colors.white, size: 11),
            SizedBox(width: 4),
            Text('Open', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    ]),
  );
}
