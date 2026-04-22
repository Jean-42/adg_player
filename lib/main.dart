import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'services/audio_handler.dart';
import 'services/player_controller.dart';
import 'theme.dart';
import 'screens/player_screen.dart';
import 'screens/add_tab.dart';
import 'screens/queue_tab.dart';
import 'screens/radio_tab.dart';
import 'screens/download_tab.dart';
import 'screens/settings_tab.dart';
import 'widgets/mini_controls.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Try to init audio_service with a 5s timeout.
  // If it hangs or fails the app still launches normally —
  // just without media notification / background audio.
  AdgAudioHandler audioHandler;
  try {
    audioHandler = await AudioService.init(
      builder: () => AdgAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId:   'com.adg.mediaplayer.audio',
        androidNotificationChannelName: 'ADG Media Player',
        androidNotificationOngoing:     true,
        androidStopForegroundOnPause:   true,
        notificationColor:              Color(0xFF6c63ff),
        androidNotificationIcon:        'mipmap/ic_launcher',
        androidShowNotificationBadge:   true,
      ),
    ).timeout(
  const Duration(seconds: 30),  // increase timeout or remove it entirely
  onTimeout: () {
    // Do NOT fall back to a plain handler; throw an error so you know something is wrong.
    throw Exception('AudioService.init timed out');
  },
);
  } catch (e) {
    debugPrint('[ADG] AudioService.init failed: $e');
    audioHandler = AdgAudioHandler();
  }

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF12121a),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(
    ChangeNotifierProvider(
      create: (_) => PlayerController(audioHandler: audioHandler),
      child: const AdgPlayerApp(),
    ),
  );
}

class AdgPlayerApp extends StatelessWidget {
  const AdgPlayerApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'ADG Media Player',
    debugShowCheckedModeBanner: false,
    theme: buildTheme(),
    home: const _RootNavigator(),
  );
}

class _RootNavigator extends StatelessWidget {
  const _RootNavigator();
  @override
  Widget build(BuildContext context) {
    final isFullscreen = context.watch<PlayerController>().isFullscreen;
    if (isFullscreen) return const FullscreenPlayer();
    return const HomeShell();
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  int _tab = 0;

  static const _tabs = [
    AddTab(),
    QueueTab(),
    DownloadTab(),
    RadioTab(),
    SettingsTab(),
  ];

  static const _navItems = [
    BottomNavigationBarItem(
        icon: Icon(Icons.add_circle_outline),
        activeIcon: Icon(Icons.add_circle),
        label: 'Add'),
    BottomNavigationBarItem(
        icon: Icon(Icons.queue_music_outlined),
        activeIcon: Icon(Icons.queue_music),
        label: 'Queue'),
    BottomNavigationBarItem(
        icon: Icon(Icons.download_outlined),
        activeIcon: Icon(Icons.download),
        label: 'Download'),
    BottomNavigationBarItem(
        icon: Icon(Icons.radio_outlined),
        activeIcon: Icon(Icons.radio),
        label: 'Radio'),
    BottomNavigationBarItem(
        icon: Icon(Icons.settings_outlined),
        activeIcon: Icon(Icons.settings),
        label: 'Settings'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        debugPrint('[ADG] App paused, keeping audio service running');
        break;
      case AppLifecycleState.resumed:
        debugPrint('[ADG] App resumed');
        break;
      case AppLifecycleState.inactive:
        debugPrint('[ADG] App inactive');
        break;
      case AppLifecycleState.detached:
        debugPrint('[ADG] App detached');
        break;
      case AppLifecycleState.hidden:
        debugPrint('[ADG] App hidden');
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0a0f),
      body: SafeArea(
        child: Column(children: [
          _AppBar(currentTab: _tab, onTabChanged: (i) => setState(() => _tab = i)),
          const PlayerSection(),
          const MiniControls(),
          Expanded(child: IndexedStack(index: _tab, children: _tabs)),
        ]),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        items: _navItems,
      ),
    );
  }
}

class _AppBar extends StatelessWidget {
  final int currentTab;
  final ValueChanged<int> onTabChanged;
  const _AppBar({required this.currentTab, required this.onTabChanged});

  @override
  Widget build(BuildContext context) {
    final queueLen = context.watch<PlayerController>().queue.length;
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF12121a),
        border: Border(bottom: BorderSide(color: Color(0x14ffffff))),
      ),
      child: Row(children: [
        Container(
          width: 26, height: 26,
          decoration: BoxDecoration(
              color: const Color(0xFF6c63ff),
              borderRadius: BorderRadius.circular(7)),
          child: const Icon(Icons.play_arrow, color: Colors.white, size: 14),
        ),
        const SizedBox(width: 8),
        const Text('ADG Media Player',
            style: TextStyle(color: Color(0xFFa78bfa), fontSize: 13,
                fontWeight: FontWeight.w700)),
        const Spacer(),
        if (queueLen > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: const Color(0xFF22223a),
                borderRadius: BorderRadius.circular(10)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.queue_music, color: Color(0xFF606080), size: 12),
              const SizedBox(width: 3),
              Text('$queueLen',
                  style: const TextStyle(
                      color: Color(0xFF606080), fontSize: 11)),
            ]),
          ),
      ]),
    );
  }
}
