import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'app_state.dart';

const ink = Color(0xFF1B3427);
const muted = Color(0xFF849187);
const line = Color(0xFFE8EDE6);
const paper = Color(0xFFFFFFFF);
const wash = Color(0xFFF7F9F5);
const page = Color(0xFFF5F8F3);
const green = Color(0xFF174B30);
const deepGreen = Color(0xFF103A24);
const greenWash = Color(0xFFE7F0E8);
const paleLime = Color(0xFFDFF0B8);
const _mainNavigationHint = 'Main navigation';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await HabitStore.load();
  runApp(DailyApp(store: store));
}

class DailyApp extends StatelessWidget {
  const DailyApp({super.key, required this.store});

  final HabitStore store;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Daily — Habit Tracker',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: page,
      colorScheme: ColorScheme.fromSeed(
        seedColor: green,
        primary: green,
        surface: paper,
        error: const Color(0xFFAD6259),
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: ink, fontSize: 12),
        bodySmall: TextStyle(color: muted, fontSize: 10),
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        filled: true,
        fillColor: Colors.white,
        hintStyle: const TextStyle(color: Color(0xFFA2ADA2), fontSize: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE3EAE1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE3EAE1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF8BB58C), width: 1.4),
        ),
      ),
      dropdownMenuTheme: const DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    ),
    home: AppShell(store: store),
  );
}

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.store});

  final HabitStore store;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late String _route;

  @override
  void initState() {
    super.initState();
    _route = widget.store.authenticated ? '/dashboard' : '/login';
  }

  void _navigate(String route) {
    if (!widget.store.authenticated && route == '/') {
      setState(() => _route = '/login');
      return;
    }
    if (route.startsWith('/') &&
        const [
          '/dashboard',
          '/habits',
          '/insights',
          '/settings',
        ].contains(route) &&
        !widget.store.authenticated) {
      setState(() => _route = '/login');
      return;
    }
    if (route == '/login' && widget.store.authenticated) {
      setState(() => _route = '/dashboard');
      return;
    }
    setState(() => _route = route);
  }

  Future<void> _signOut() async {
    setState(() => _route = '/logout-loading');
    await widget.store.signOut();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.store,
    builder: (context, _) {
      final store = widget.store;
      if (!store.authenticated &&
          const [
            '/dashboard',
            '/habits',
            '/insights',
            '/settings',
          ].contains(_route)) {
        _route = '/login';
      }
      if (store.authenticated && _route == '/login') {
        _route = '/loading';
      }
      if (_route == '/loading' || _route == '/logout-loading') {
        return BrandedLoadingScreen(
          onComplete: () => _navigate(
            _route == '/logout-loading' ? '/login' : '/dashboard',
          ),
        );
      }
      if (!store.authenticated) {
        return LoginScreen(store: store, onNavigate: _navigate);
      }
      return TrackerLayout(
        store: store,
        route: _route,
        onNavigate: _navigate,
        onLogout: _signOut,
      );
    },
  );
}

class BrandedLoadingScreen extends StatefulWidget {
  const BrandedLoadingScreen({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<BrandedLoadingScreen> createState() => _BrandedLoadingScreenState();
}

class _BrandedLoadingScreenState extends State<BrandedLoadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) widget.onComplete();
      });
    _scale = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ).drive(Tween<double>(begin: .72, end: 1));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: deepGreen,
    body: Stack(
      children: [
        const Positioned(
          top: -130,
          right: -90,
          child: _GlowOrb(size: 320, color: Color(0xFF28613A)),
        ),
        const Positioned(
          bottom: -170,
          left: -100,
          child: _GlowOrb(size: 360, color: Color(0xFF1A4A2D)),
        ),
        Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => Opacity(
              opacity: _fade.value,
              child: Transform.scale(
                scale: _scale.value,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 118,
                      height: 118,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox.expand(
                            child: CircularProgressIndicator(
                              value: _controller.value,
                              strokeWidth: 2,
                              backgroundColor: Colors.white.withValues(alpha: .16),
                              valueColor: const AlwaysStoppedAnimation(paleLime),
                            ),
                          ),
                          Container(
                            width: 82,
                            height: 82,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(26),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: .16),
                                  blurRadius: 28,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: const Center(child: BrandMark(size: 58)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'daily',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'MAKING ROOM FOR WHAT MATTERS',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .68),
                        fontSize: 9,
                        letterSpacing: 1.8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: 46,
                      child: LinearProgressIndicator(
                        value: _controller.value,
                        minHeight: 2,
                        backgroundColor: Colors.white.withValues(alpha: .18),
                        valueColor: const AlwaysStoppedAnimation(paleLime),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        colors: [color.withValues(alpha: .65), color.withValues(alpha: 0)],
      ),
    ),
  );
}

class TrackerLayout extends StatelessWidget {
  const TrackerLayout({
    super.key,
    required this.store,
    required this.route,
    required this.onNavigate,
    required this.onLogout,
  });

  final HabitStore store;
  final String route;
  final ValueChanged<String> onNavigate;
  final VoidCallback onLogout;

  static const _routes = ['/dashboard', '/habits', '/insights', '/settings'];
  static const _labels = ['Dashboard', 'My Habits', 'Insights', 'Settings'];
  static const _icons = [
    Icons.home_outlined,
    Icons.check_circle_outline,
    Icons.trending_up,
    Icons.settings_outlined,
  ];

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      final mobile = width < 640;
      final compact = width < 820;
      return Scaffold(
        body: Row(
          children: [
            if (!mobile)
              _Sidebar(
                store: store,
                route: route,
                compact: compact,
                onNavigate: onNavigate,
                onLogout: onLogout,
              ),
            Expanded(
              child: Column(
                children: [
                  _TopBar(store: store),
                  if (store.persistenceError != null)
                    MaterialBanner(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 6,
                      ),
                      backgroundColor: const Color(0xFFFFF5E9),
                      content: Text(
                        store.persistenceError!,
                        style: const TextStyle(
                          color: Color(0xFF875D3F),
                          fontSize: 11,
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: store.clearPersistenceError,
                          child: const Text('Dismiss'),
                        ),
                      ],
                    ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        mobile ? 18 : (compact ? 27 : 42),
                        mobile ? 20 : 34,
                        mobile ? 18 : (compact ? 27 : 42),
                        mobile ? 30 : 50,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1380),
                          child: _buildPage(width),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: mobile
            ? SafeArea(
                top: false,
                child: Container(
                  height: 72,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFCFDFC),
                    border: Border(top: BorderSide(color: line)),
                  ),
                  child: Row(
                    children: List.generate(_routes.length, (index) {
                      final active = route == _routes[index];
                      return Expanded(
                        child: Semantics(
                          button: true,
                          selected: active,
                          label: _labels[index],
                          hint: _mainNavigationHint,
                          onTap: () => onNavigate(_routes[index]),
                          child: InkWell(
                            onTap: () => onNavigate(_routes[index]),
                            child: ExcludeSemantics(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: active
                                          ? const Color(0xFFE8F1E5)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Icon(
                                      _icons[index],
                                      size: 21,
                                      color: active
                                          ? deepGreen
                                          : const Color(0xFF647266),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    _labels[index],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: active
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: active
                                          ? deepGreen
                                          : const Color(0xFF647266),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              )
            : null,
      );
    },
  );

  Widget _buildPage(double width) {
    switch (route) {
      case '/habits':
        return HabitsScreen(store: store);
      case '/insights':
        return InsightsScreen(store: store, width: width);
      case '/settings':
        return SettingsScreen(store: store, onLogout: onLogout);
      default:
        return DashboardScreen(
          store: store,
          width: width,
          onNavigate: onNavigate,
        );
    }
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.store,
    required this.route,
    required this.compact,
    required this.onNavigate,
    required this.onLogout,
  });

  final HabitStore store;
  final String route;
  final bool compact;
  final ValueChanged<String> onNavigate;
  final VoidCallback onLogout;

  static const _routes = ['/dashboard', '/habits', '/insights', '/settings'];
  static const _labels = ['Dashboard', 'My Habits', 'Insights', 'Settings'];
  static const _icons = [
    Icons.home_outlined,
    Icons.check_circle_outline,
    Icons.trending_up,
    Icons.settings_outlined,
  ];

  @override
  Widget build(BuildContext context) => Container(
    width: compact ? 72 : 244,
    padding: EdgeInsets.fromLTRB(compact ? 8 : 19, 25, compact ? 8 : 19, 18),
    decoration: const BoxDecoration(
      color: paper,
      border: Border(right: BorderSide(color: Color(0xFFEAF0E8))),
    ),
    child: Column(
      crossAxisAlignment: compact
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        if (compact)
          const Padding(
            padding: EdgeInsets.only(bottom: 29),
            child: Tooltip(
              message: 'Daily Habit Tracker',
              child: BrandMark(size: 42),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 4, 0, 39),
            child: Brand(onTap: () => onNavigate('/dashboard')),
          ),
        if (!compact)
          const Padding(
            padding: EdgeInsets.only(left: 12, bottom: 12),
            child: Text(
              'MENU',
              style: TextStyle(
                color: Color(0xFFA3ACA3),
                fontSize: 9,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ...List.generate(_routes.length, (index) {
          final active = route == _routes[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Semantics(
              button: true,
              selected: active,
              label: _labels[index],
              hint: _mainNavigationHint,
              onTap: () => onNavigate(_routes[index]),
              child: Tooltip(
                message: compact ? _labels[index] : '',
                child: InkWell(
                  onTap: () => onNavigate(_routes[index]),
                  borderRadius: BorderRadius.circular(9),
                  child: ExcludeSemantics(
                    child: Container(
                      height: 48,
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 0 : 13,
                      ),
                      decoration: BoxDecoration(
                        color: active ? greenWash : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Row(
                        mainAxisAlignment: compact
                            ? MainAxisAlignment.center
                            : MainAxisAlignment.start,
                        children: [
                          Container(
                            width: 23,
                            height: 23,
                            decoration: BoxDecoration(
                              color: active
                                  ? const Color(0xFFDDECDD)
                                  : const Color(0xFFEDF5EB),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Icon(
                              _icons[index],
                              size: 14,
                              color: active
                                  ? deepGreen
                                  : const Color(0xFF5B7D60),
                            ),
                          ),
                          if (!compact) ...[
                            const SizedBox(width: 12),
                            Text(
                              _labels[index],
                              style: TextStyle(
                                color: active
                                    ? deepGreen
                                    : const Color(0xFF748176),
                                fontSize: 12,
                                fontWeight: active
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
        const Spacer(),
        if (!compact) const Divider(height: 1, color: Color(0xFFEDF0EB)),
        SizedBox(height: compact ? 12 : 17),
        if (compact)
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFFE9F2E3),
            foregroundColor: const Color(0xFF4F8052),
            child: Text(store.name.isEmpty ? 'A' : store.name[0].toUpperCase()),
          )
        else
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFE9F2E3),
                foregroundColor: const Color(0xFF4F8052),
                child: Text(
                  store.name.isEmpty ? 'A' : store.name[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store.name,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Your space',
                      style: TextStyle(color: muted, fontSize: 9),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onLogout,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF9A756E),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(48, 44),
                ),
                child: const Text('Log out', style: TextStyle(fontSize: 10)),
              ),
            ],
          ),
      ],
    ),
  );
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.store});

  final HabitStore store;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final date =
        '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
    return LayoutBuilder(
      builder: (context, constraints) {
        final mobile = constraints.maxWidth < 640;
        return Container(
          height: mobile ? 60 : 68,
          padding: EdgeInsets.symmetric(horizontal: mobile ? 18 : 30),
          decoration: const BoxDecoration(
            color: Color(0xF2FFFFFF),
            border: Border(bottom: BorderSide(color: Color(0xFFEBF0E9))),
          ),
          child: Row(
            children: [
              if (mobile) ...[
                const BrandMark(size: 34),
                const SizedBox(width: 10),
                const Text(
                  'daily',
                  style: TextStyle(
                    color: ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.7,
                  ),
                ),
                const Spacer(),
                Text(
                  '${months[now.month - 1]} ${now.day}',
                  style: const TextStyle(
                    color: Color(0xFF849187),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 11),
                CircleAvatar(
                  radius: 17,
                  backgroundColor: const Color(0xFFE9F2E3),
                  foregroundColor: green,
                  child: Text(
                    store.name.isEmpty ? 'A' : store.name[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ] else
                Text(
                  date,
                  style: const TextStyle(color: Color(0xFF8C988E), fontSize: 11),
                ),
            ],
          ),
        );
      },
    );
  }
}

class Brand extends StatelessWidget {
  const Brand({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = SizedBox(
      height: 40,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const BrandMark(),
          const SizedBox(width: 11),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'daily',
                style: TextStyle(
                  color: ink,
                  fontSize: 22,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.3,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'HABIT TRACKER',
                style: TextStyle(
                  color: Color(0xFF94A096),
                  fontSize: 8,
                  letterSpacing: 1.75,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (onTap == null) return content;
    return InkWell(onTap: onTap, child: content);
  }
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: const Color(0xFF1B5736),
      borderRadius: BorderRadius.circular(13),
    ),
    child: Stack(
      alignment: Alignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 4, bottom: 2),
          child: Text(
            'd',
            style: TextStyle(
              color: Colors.white,
              fontSize: size * .7,
              height: 1,
              fontWeight: FontWeight.w800,
              letterSpacing: -3,
            ),
          ),
        ),
        Positioned(
          right: size * .15,
          top: size * .08,
          child: Text(
            '+',
            style: TextStyle(
              color: paleLime,
              fontSize: size * .28,
              height: 1,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = false,
    this.height = 40,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;
  final double height;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final button = FilledButton(
      onPressed: busy ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: green,
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFF789681),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        minimumSize: Size(0, height),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label),
          if (icon != null) ...[const SizedBox(width: 8), Icon(icon, size: 16)],
          if (busy) ...[
            const SizedBox(width: 8),
            const SizedBox.square(
              dimension: 13,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class SectionKicker extends StatelessWidget {
  const SectionKicker(
    this.text, {
    super.key,
    this.color = const Color(0xFF82A17F),
  });

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: TextStyle(
      color: color,
      fontSize: 9,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.45,
    ),
  );
}

class AppPanel extends StatelessWidget {
  const AppPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color = paper,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: color,
      border: Border.all(color: line),
      borderRadius: BorderRadius.circular(13),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0427452D),
          blurRadius: 12,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: child,
  );
}

Widget pageHeading(
  String eyebrow,
  String title,
  String subtitle, {
  Widget? trailing,
}) => Padding(
  padding: const EdgeInsets.only(bottom: 24),
  child: LayoutBuilder(
    builder: (context, constraints) {
      final titleContent = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionKicker(eyebrow),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: ink,
              fontSize: MediaQuery.sizeOf(context).width < 640 ? 27 : 29,
              height: 1.15,
              letterSpacing: -1.1,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 7),
            Text(
              subtitle,
              style: const TextStyle(
                color: Color(0xFF89958B),
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],
        ],
      );
      if (trailing == null) return titleContent;
      if (constraints.maxWidth < 580) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [titleContent, const SizedBox(height: 14), trailing],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: titleContent),
          trailing,
        ],
      );
    },
  ),
);

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key, required this.onNavigate});

  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF8FAF6),
    body: LayoutBuilder(
      builder: (context, constraints) {
        final mobile = constraints.maxWidth < 900;
        return SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1600),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: mobile ? 22 : constraints.maxWidth * .071,
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: 88,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Brand(onTap: () => onNavigate('/')),
                          TextButton.icon(
                            onPressed: () => onNavigate('/login'),
                            iconAlignment: IconAlignment.end,
                            icon: const Icon(Icons.north_east, size: 14),
                            label: const Text('Sign in'),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF56705A),
                              textStyle: const TextStyle(fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (mobile)
                      Column(
                        children: [
                          _LandingCopy(onNavigate: onNavigate, mobile: true),
                          const SizedBox(height: 12),
                          const SizedBox(height: 340, child: _LandingArtwork()),
                        ],
                      )
                    else
                      SizedBox(
                        height: 540,
                        child: Row(
                          children: [
                            Expanded(
                              flex: 9,
                              child: _LandingCopy(onNavigate: onNavigate),
                            ),
                            const Expanded(flex: 10, child: _LandingArtwork()),
                          ],
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Color(0xFFE9EEE6)),
                          bottom: BorderSide(color: Color(0xFFE9EEE6)),
                        ),
                      ),
                      child: mobile
                          ? const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SectionKicker('Build a routine that fits you'),
                                SizedBox(height: 13),
                                Text(
                                  '01  Choose what matters     ·     02  Check in as you go     ·     03  Celebrate showing up',
                                  style: TextStyle(
                                    color: Color(0xFF738273),
                                    fontSize: 10,
                                    height: 1.8,
                                  ),
                                ),
                              ],
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SectionKicker('Build a routine that fits you'),
                                Text(
                                  '01   Choose what matters     ·     02   Check in as you go     ·     03   Celebrate showing up',
                                  style: TextStyle(
                                    color: Color(0xFF738273),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 22),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text(
                            '© Daily Habit Tracker',
                            style: TextStyle(
                              color: Color(0xFFABB4A8),
                              fontSize: 9,
                            ),
                          ),
                          Text(
                            'Grow at your own pace  ✳',
                            style: TextStyle(
                              color: Color(0xFFABB4A8),
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

class _LandingCopy extends StatelessWidget {
  const _LandingCopy({required this.onNavigate, this.mobile = false});

  final ValueChanged<String> onNavigate;
  final bool mobile;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(
      top: mobile ? 30 : 0,
      bottom: 10,
      right: mobile ? 0 : 15,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE6EDDF)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, color: Color(0xFF7DBA7C), size: 7),
              SizedBox(width: 8),
              Text(
                'YOUR DAILY GROWTH COMPANION',
                style: TextStyle(
                  color: Color(0xFF7D9672),
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.05,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 25),
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(
                text: 'Make space for\n',
                style: TextStyle(
                  color: Color(0xFF193B28),
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextSpan(
                text: 'better habits.',
                style: TextStyle(
                  color: const Color(0xFF396B42),
                  fontFamily: 'Georgia',
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          style: TextStyle(
            fontSize: mobile ? 54 : 69,
            height: .99,
            letterSpacing: mobile ? -3 : -4.2,
          ),
        ),
        const SizedBox(height: 17),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 410),
          child: Text(
            'A calm place to build routines that feel good and last. Start small, check in each day, and watch your progress grow.',
            style: TextStyle(
              color: Color(0xFF879387),
              fontSize: 13,
              height: 1.8,
            ),
          ),
        ),
        const SizedBox(height: 27),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 12,
          children: [
            PrimaryButton(
              label: 'Start tracking',
              icon: Icons.arrow_forward,
              height: 44,
              onPressed: () => onNavigate('/login'),
            ),
            const Text(
              'No streak pressure. Just progress.',
              style: TextStyle(color: Color(0xFFA0A99D), fontSize: 9),
            ),
          ],
        ),
        const SizedBox(height: 36),
        const Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 5,
          children: [
            _ProofAvatars(),
            Text(
              'One good day at a time',
              style: TextStyle(color: Color(0xFF9AA499), fontSize: 9),
            ),
            Text('•', style: TextStyle(color: Color(0xFFB3C0AD))),
            Text(
              'Made for real life',
              style: TextStyle(color: Color(0xFF9AA499), fontSize: 9),
            ),
          ],
        ),
      ],
    ),
  );
}

class _ProofAvatars extends StatelessWidget {
  const _ProofAvatars();

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 58,
    height: 24,
    child: Stack(
      children: const [
        Positioned(
          left: 0,
          child: _ProofAvatar('A', Color(0xFFDCE9D3), Color(0xFF63815E)),
        ),
        Positioned(
          left: 17,
          child: _ProofAvatar('J', Color(0xFFE9E8D7), Color(0xFF92875E)),
        ),
        Positioned(
          left: 34,
          child: _ProofAvatar('M', Color(0xFFDCE9E5), Color(0xFF64867A)),
        ),
      ],
    ),
  );
}

class _ProofAvatar extends StatelessWidget {
  const _ProofAvatar(this.label, this.background, this.foreground);

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: 12,
    backgroundColor: const Color(0xFFF8FAF6),
    child: CircleAvatar(
      radius: 10,
      backgroundColor: background,
      foregroundColor: foreground,
      child: Text(
        label,
        style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w700),
      ),
    ),
  );
}

class _LandingArtwork extends StatelessWidget {
  const _LandingArtwork();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final scale = math.min(1.0, constraints.maxWidth / 450);
      return Center(
        child: Transform.scale(
          scale: scale,
          child: SizedBox(
            width: 440,
            height: 425,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 400,
                  height: 365,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Color(0xFFEAF2DF),
                        Color(0xFFF1F5EB),
                        Color(0x00F8FAF6),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 39,
                  right: 41,
                  child: Container(
                    width: 67,
                    height: 67,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFF2EDCF),
                    ),
                  ),
                ),
                Positioned(
                  top: 65,
                  left: 29,
                  child: Transform.rotate(
                    angle: -.052,
                    child: Container(
                      width: 300,
                      padding: const EdgeInsets.fromLTRB(18, 17, 18, 15),
                      decoration: BoxDecoration(
                        color: const Color(0xF8FFFFFF),
                        border: Border.all(color: const Color(0xFFE9EEE6)),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x12385B35),
                            blurRadius: 35,
                            offset: Offset(0, 16),
                          ),
                        ],
                      ),
                      child: const _ArtworkCard(),
                    ),
                  ),
                ),
                const Positioned(right: 27, bottom: 27, child: _Plant()),
                Positioned(
                  right: 5,
                  top: 93,
                  child: Transform.rotate(
                    angle: .07,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFEDF0E5)),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [
                          BoxShadow(color: Color(0x10395630), blurRadius: 15),
                        ],
                      ),
                      child: const Text(
                        '✦  Little by little',
                        style: TextStyle(color: Color(0xFF77906F), fontSize: 9),
                      ),
                    ),
                  ),
                ),
                const Positioned(
                  right: 34,
                  bottom: 3,
                  child: Text(
                    'A softer way to stay consistent',
                    style: TextStyle(
                      color: Color(0xFFA0AA9D),
                      fontFamily: 'Georgia',
                      fontStyle: FontStyle.italic,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _ArtworkCard extends StatelessWidget {
  const _ArtworkCard();

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'THIS WEEK',
                style: TextStyle(
                  color: Color(0xFF779170),
                  fontSize: 8,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Your steady rhythm',
                style: TextStyle(color: Color(0xFFA4ADA1), fontSize: 9),
              ),
            ],
          ),
          Text('···', style: TextStyle(color: Color(0xFFAAB3A8), fontSize: 20)),
        ],
      ),
      const SizedBox(height: 14),
      Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F8F2),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          children: [
            const _Ring(value: .72, size: 51, label: '72%'),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "You're growing",
                    style: TextStyle(
                      color: Color(0xFF5C7059),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    '12 check-ins this week',
                    style: TextStyle(color: Color(0xFF9AA69A), fontSize: 8),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const _ArtworkHabit(
        icon: '✿',
        name: 'Morning walk',
        category: 'Movement',
        color: Color(0xFFE8F2E8),
      ),
      const _ArtworkHabit(
        icon: '▤',
        name: 'Read a little',
        category: 'Learning',
        color: Color(0xFFF0F1E4),
      ),
      const SizedBox(height: 13),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (index) {
          final labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
          final checked = index < 5;
          return Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: checked ? const Color(0xFF376C45) : Colors.transparent,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              checked ? '✓' : labels[index],
              style: TextStyle(
                color: checked ? Colors.white : const Color(0xFFAAB3A8),
                fontSize: 8,
              ),
            ),
          );
        }),
      ),
    ],
  );
}

class _ArtworkHabit extends StatelessWidget {
  const _ArtworkHabit({
    required this.icon,
    required this.name,
    required this.category,
    required this.color,
  });

  final String icon;
  final String name;
  final String category;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    height: 39,
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Color(0xFFF0F2ED))),
    ),
    child: Row(
      children: [
        Container(
          width: 23,
          height: 23,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(icon, style: const TextStyle(fontSize: 11, color: green)),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: Color(0xFF5D6E5C),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                category,
                style: const TextStyle(color: Color(0xFFA6AFA4), fontSize: 7),
              ),
            ],
          ),
        ),
        const Icon(Icons.check, size: 14, color: Color(0xFF76A374)),
      ],
    ),
  );
}

class _Plant extends StatelessWidget {
  const _Plant();

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 170,
    height: 214,
    child: Stack(
      children: [
        Positioned(
          bottom: 87,
          left: 83,
          child: Transform.rotate(
            angle: .03,
            child: Container(
              width: 4,
              height: 105,
              decoration: BoxDecoration(
                color: const Color(0xFF79A371),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        const Positioned(
          left: 37,
          top: 44,
          child: _Leaf(color: Color(0xFF89AD76), angle: .16),
        ),
        const Positioned(
          left: 78,
          top: 60,
          child: _Leaf(color: Color(0xFF6F9B69), angle: 3.2),
        ),
        const Positioned(
          left: 28,
          top: 91,
          child: _Leaf(color: Color(0xFF9CBA7D), angle: -.15),
        ),
        const Positioned(
          left: 82,
          top: 24,
          child: _Leaf(color: Color(0xFF759C6D), angle: 3.25, width: 41),
        ),
        Positioned(
          bottom: 10,
          left: 42,
          child: ClipPath(
            clipper: _PotClipper(),
            child: Container(
              width: 98,
              height: 79,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFBDCBA9),
                    Color(0xFFD4DDC7),
                    Color(0xFFB8CAA6),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 79,
          left: 46,
          child: Container(
            width: 91,
            height: 10,
            decoration: const BoxDecoration(color: Color(0xFFAABC99)),
          ),
        ),
      ],
    ),
  );
}

class _PotClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => Path()
    ..moveTo(size.width * .08, 0)
    ..lineTo(size.width * .92, 0)
    ..lineTo(size.width * .78, size.height)
    ..lineTo(size.width * .22, size.height)
    ..close();

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _Leaf extends StatelessWidget {
  const _Leaf({required this.color, required this.angle, this.width = 48});

  final Color color;
  final double angle;
  final double width;

  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: angle,
    child: Container(
      width: width,
      height: 24,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(2),
          bottomRight: Radius.circular(24),
        ),
      ),
    ),
  );
}

class _Ring extends StatelessWidget {
  const _Ring({required this.value, required this.size, required this.label});

  final double value;
  final double size;
  final String label;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            value: value,
            strokeWidth: size * .11,
            backgroundColor: const Color(0xFFE3EADF),
            color: const Color(0xFF376C45),
            strokeCap: StrokeCap.round,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: const Color(0xFF315E3B),
            fontSize: size * .23,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.store, required this.onNavigate});

  final HabitStore store;
  final ValueChanged<String> onNavigate;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _error;
  bool _busy = false;
  bool _hidePassword = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _error = null);
    if (_email.text.trim().isEmpty || _password.text.isEmpty) {
      setState(() => _error = 'Enter your email and password to continue.');
      return;
    }
    setState(() => _busy = true);
    final accepted = await widget.store.signIn(_email.text, _password.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!accepted) {
      setState(
        () => _error = 'We could not find an account with those details.',
      );
    }
  }

  @override
  Widget build(BuildContext context) => AuthFrame(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Brand(),
        const SizedBox(height: 34),
        const SectionKicker('A fresh day, a fresh start'),
        const SizedBox(height: 10),
        const Text(
          'Welcome back',
          style: TextStyle(
            color: Color(0xFF2E4935),
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          'Sign in to pick up where your little habits left off.',
          style: TextStyle(color: Color(0xFF89968A), fontSize: 11, height: 1.6),
        ),
        const SizedBox(height: 16),
        _FieldLabel('Email address'),
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          decoration: const InputDecoration(hintText: 'you@example.com'),
        ),
        const SizedBox(height: 14),
        _FieldLabel('Password'),
        TextField(
          controller: _password,
          obscureText: _hidePassword,
          autofillHints: const [AutofillHints.password],
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            hintText: 'Your password',
            suffixIcon: IconButton(
              tooltip: _hidePassword ? 'Show password' : 'Hide password',
              onPressed: () => setState(() => _hidePassword = !_hidePassword),
              icon: Icon(
                _hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                size: 19,
              ),
            ),
          ),
        ),
        if (_error != null) _FormError(_error!),
        const SizedBox(height: 19),
        PrimaryButton(
          label: 'Sign in',
          icon: Icons.arrow_forward,
          onPressed: _submit,
          busy: _busy,
          expand: true,
        ),
        const SizedBox(height: 20),
        const Divider(color: Color(0xFFEFF2ED)),
        const SizedBox(height: 13),
        const Text(
          'Demo sign-in only. Your account is stored locally on this device; no server is used.',
          style: TextStyle(color: Color(0xFF9AA499), fontSize: 9, height: 1.6),
        ),
      ],
    ),
  );
}

class AuthFrame extends StatelessWidget {
  const AuthFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(.65, -.6),
          radius: 1.4,
          colors: [Color(0xFFE7F0DD), Color(0xFFF6F9F3), Color(0xFFF6F9F3)],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final mobile = constraints.maxWidth < 640;
          return Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: mobile ? 18 : 22,
                    vertical: mobile ? 24 : 40,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Container(
                      padding: EdgeInsets.all(mobile ? 24 : 34),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFE6EDE3)),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1228442A),
                            blurRadius: 60,
                            offset: Offset(0, 20),
                          ),
                        ],
                      ),
                      child: child,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: mobile ? 18 : constraints.maxWidth * .08,
                bottom: mobile ? 8 : 30,
                child: const IgnorePointer(
                  child: Text(
                    '✳',
                    style: TextStyle(color: Color(0xFFC8DCBC), fontSize: 38),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Text(
      text,
      style: const TextStyle(
        color: Color(0xFF667568),
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _FormError extends StatelessWidget {
  const _FormError(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Text(
      text,
      style: const TextStyle(
        color: Color(0xFFAD6259),
        fontSize: 10,
        height: 1.5,
      ),
    ),
  );
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.store,
    required this.width,
    required this.onNavigate,
  });

  final HabitStore store;
  final double width;
  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context) {
    final done = store.habits.where(store.isDoneToday).length;
    final progress = store.habits.isEmpty
        ? 0
        : (done * 100 / store.habits.length).round();
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 18
        ? 'Good afternoon'
        : 'Good evening';
    final twoColumns = width >= 850;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        pageHeading(
          'Your personal growth space',
          '$greeting, ${store.name}  ✳',
          'Every little action is a vote for the person you want to become.',
          trailing: PrimaryButton(
            label: 'Manage habits',
            icon: Icons.arrow_forward,
            onPressed: () => onNavigate('/habits'),
          ),
        ),
        if (twoColumns)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 13,
                child: _TodayPanel(
                  store: store,
                  done: done,
                  progress: progress,
                  onNavigate: onNavigate,
                ),
              ),
              const SizedBox(width: 17),
              Expanded(
                flex: 8,
                child: _DashboardAside(store: store, onNavigate: onNavigate),
              ),
            ],
          )
        else ...[
          _TodayPanel(
            store: store,
            done: done,
            progress: progress,
            onNavigate: onNavigate,
          ),
          const SizedBox(height: 16),
          _DashboardAside(store: store, onNavigate: onNavigate),
        ],
      ],
    );
  }
}

class _TodayPanel extends StatelessWidget {
  const _TodayPanel({
    required this.store,
    required this.done,
    required this.progress,
    required this.onNavigate,
  });

  final HabitStore store;
  final int done;
  final int progress;
  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final dateLabel = '${months[today.month - 1]} ${today.day}';
    return AppPanel(
      padding: const EdgeInsets.fromLTRB(23, 21, 23, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            runSpacing: 10,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionKicker("Today's check-in"),
                  SizedBox(height: 6),
                  Text(
                    'Your daily rhythm',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -.3,
                    ),
                  ),
                ],
              ),
              _SoftTag(dateLabel),
            ],
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F8F3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '$done',
                              style: const TextStyle(
                                color: ink,
                                fontSize: 27,
                                height: 1,
                                letterSpacing: -1,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            TextSpan(
                              text: ' / ${store.habits.length}',
                              style: const TextStyle(
                                color: Color(0xFFA6B0A5),
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'habits completed',
                        style: TextStyle(
                          color: Color(0xFF536B58),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        progress == 100 && store.habits.isNotEmpty
                            ? 'You showed up for every habit today. Lovely work!'
                            : 'A small step still counts. Keep going at your own pace.',
                        style: const TextStyle(
                          color: Color(0xFF9AA499),
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
                _Ring(value: progress / 100, size: 75, label: '$progress%'),
              ],
            ),
          ),
          if (store.habits.isNotEmpty)
            ...store.habits
                .take(4)
                .map((habit) => _TodayHabitRow(store: store, habit: habit))
          else
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 22),
              child: Text(
                'Your first habit is waiting to be added.',
                style: TextStyle(color: muted, fontSize: 11),
              ),
            ),
          InkWell(
            onTap: () => onNavigate('/habits'),
            child: const SizedBox(
              height: 47,
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'See all habits',
                      style: TextStyle(
                        color: deepGreen,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, color: deepGreen, size: 14),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayHabitRow extends StatelessWidget {
  const _TodayHabitRow({required this.store, required this.habit});

  final HabitStore store;
  final Habit habit;

  @override
  Widget build(BuildContext context) {
    final complete = store.isDoneToday(habit);
    return Container(
      constraints: const BoxConstraints(minHeight: 61),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF0F2EE))),
      ),
      child: Row(
        children: [
          _CheckButton(
            complete: complete,
            habitName: habit.name,
            onPressed: () => store.toggleToday(habit.id),
          ),
          const SizedBox(width: 11),
          _ColorDot(colorName: habit.color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.name,
                  style: const TextStyle(
                    color: Color(0xFF354639),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  habit.category,
                  style: const TextStyle(color: Color(0xFFA0A99F), fontSize: 9),
                ),
              ],
            ),
          ),
          const Icon(Icons.auto_awesome, size: 11, color: Color(0xFF8DA17D)),
          const SizedBox(width: 4),
          Text(
            '${store.currentStreak(habit)} day${store.currentStreak(habit) == 1 ? '' : 's'}',
            style: const TextStyle(color: Color(0xFF8DA17D), fontSize: 9),
          ),
        ],
      ),
    );
  }
}

class _CheckButton extends StatelessWidget {
  const _CheckButton({
    required this.complete,
    required this.habitName,
    required this.onPressed,
  });

  final bool complete;
  final String habitName;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    toggled: complete,
    label: habitName,
    hint: complete ? 'Mark incomplete' : 'Mark complete',
    onTap: onPressed,
    child: GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.opaque,
      child: ExcludeSemantics(
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: Container(
              width: 21,
              height: 21,
              decoration: BoxDecoration(
                color: complete ? const Color(0xFF285C39) : Colors.white,
                border: Border.all(
                  color: complete
                      ? const Color(0xFF285C39)
                      : const Color(0xFFDBE4D8),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: complete
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ),
        ),
      ),
    ),
  );
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.colorName});

  final String colorName;

  @override
  Widget build(BuildContext context) => Container(
    width: 8,
    height: 8,
    decoration: BoxDecoration(
      color: habitColor(colorName),
      shape: BoxShape.circle,
    ),
  );
}

Color habitColor(String name) {
  switch (name) {
    case 'sage':
      return const Color(0xFFA5B987);
    case 'lime':
      return const Color(0xFFC6D971);
    case 'forest':
      return const Color(0xFF729C76);
    default:
      return const Color(0xFF82BDA0);
  }
}

class _DashboardAside extends StatelessWidget {
  const _DashboardAside({required this.store, required this.onNavigate});

  final HabitStore store;
  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context) {
    final days = store.weekDays();
    final counts = days
        .map(
          (day) => store.habits
              .where((habit) => habit.completedDates.contains(day.key))
              .length,
        )
        .toList();
    final total = counts.fold<int>(0, (sum, count) => sum + count);
    return Column(
      children: [
        AppPanel(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionKicker('A look back'),
                        SizedBox(height: 6),
                        Text(
                          'This week',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => onNavigate('/insights'),
                    iconAlignment: IconAlignment.end,
                    icon: const Icon(Icons.arrow_forward, size: 12),
                    label: const Text('Details'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF759171),
                      textStyle: const TextStyle(fontSize: 9),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 11),
              SizedBox(
                height: 124,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: List.generate(7, (index) {
                    final maxCount = math.max(1, store.habits.length);
                    final pct = counts[index] == 0
                        ? .07
                        : math.max(.07, counts[index] / maxCount);
                    return Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: FractionallySizedBox(
                                heightFactor: pct.toDouble(),
                                child: Container(
                                  width: 21,
                                  decoration: BoxDecoration(
                                    color: days[index].key == store.todayKey()
                                        ? const Color(0xFF376C45)
                                        : const Color(0xFFDFEADD),
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            days[index].label.substring(0, 1),
                            style: const TextStyle(
                              color: Color(0xFFA1AAA0),
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F8F3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE4EFE3),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: const Icon(
                        Icons.trending_up,
                        size: 15,
                        color: Color(0xFF6D946B),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$total check-ins',
                            style: const TextStyle(
                              color: Color(0xFF536954),
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'across ${store.habits.length} habits this week',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF9BA69A),
                              fontSize: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 132),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF2E5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              const Positioned(
                top: -7,
                left: 0,
                child: Text(
                  '“',
                  style: TextStyle(
                    color: Color(0xFF9DB58D),
                    fontSize: 32,
                    height: 1,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 17, right: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'We are what we repeatedly do. Excellence, then, is not an act, but a habit.',
                      style: TextStyle(
                        color: Color(0xFF64765F),
                        fontFamily: 'Georgia',
                        fontSize: 12,
                        height: 1.55,
                      ),
                    ),
                    SizedBox(height: 9),
                    Text(
                      '— Aristotle',
                      style: TextStyle(color: Color(0xFF899982), fontSize: 9),
                    ),
                  ],
                ),
              ),
              const Positioned(
                right: 0,
                bottom: 0,
                child: Icon(
                  Icons.auto_awesome,
                  size: 14,
                  color: Color(0xFFAAC097),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SoftTag extends StatelessWidget {
  const _SoftTag(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: const Color(0xFFFBFCFA),
      border: Border.all(color: const Color(0xFFEDF1EB)),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Text(
      label,
      style: const TextStyle(color: Color(0xFF879388), fontSize: 9),
    ),
  );
}

const _categories = [
  'Health',
  'Movement',
  'Learning',
  'Mindfulness',
  'Productivity',
  'Other',
];
const _frequencies = ['Daily', 'Weekdays', 'Weekly'];

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key, required this.store});

  final HabitStore store;

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  final _search = TextEditingController();
  String _category = 'All habits';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Habit> get _visible => widget.store.habits.where((habit) {
    final matchesQuery = habit.name.toLowerCase().contains(
      _search.text.toLowerCase(),
    );
    return matchesQuery &&
        (_category == 'All habits' || habit.category == _category);
  }).toList();

  Future<void> _showHabitForm({Habit? habit}) async {
    final name = TextEditingController(text: habit?.name ?? '');
    var category = habit?.category ?? 'Health';
    var frequency = habit?.frequency ?? 'Daily';
    String? error;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          insetPadding: const EdgeInsets.all(18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 25, 24, 22),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: SectionKicker('A little intention'),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          icon: const Icon(Icons.close, size: 19),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                    Text(
                      habit == null ? 'Create a habit' : 'Edit your habit',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -.6,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Keep it simple and make it yours.',
                      style: TextStyle(color: muted, fontSize: 11),
                    ),
                    const SizedBox(height: 19),
                    const _FieldLabel('Habit name'),
                    TextField(
                      controller: name,
                      maxLength: 56,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Stretch for five minutes',
                        counterText: '',
                      ),
                    ),
                    if (error != null) _FormError(error!),
                    const SizedBox(height: 14),
                    const _FieldLabel('Category'),
                    _DropdownField(
                      value: category,
                      items: _categories,
                      onChanged: (value) =>
                          setDialogState(() => category = value!),
                    ),
                    const SizedBox(height: 14),
                    const _FieldLabel('Frequency'),
                    _DropdownField(
                      value: frequency,
                      items: _frequencies,
                      onChanged: (value) =>
                          setDialogState(() => frequency = value!),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF6E7B70),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        PrimaryButton(
                          label: habit == null
                              ? 'Create habit'
                              : 'Save changes',
                          onPressed: () {
                            if (name.text.trim().isEmpty) {
                              setDialogState(
                                () => error = 'Give your habit a name first.',
                              );
                              return;
                            }
                            if (habit == null) {
                              widget.store.createHabit(
                                name: name.text,
                                category: category,
                                frequency: frequency,
                              );
                            } else {
                              widget.store.updateHabit(
                                habit.id,
                                name: name.text,
                                category: category,
                                frequency: frequency,
                              );
                            }
                            Navigator.pop(dialogContext);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    name.dispose();
  }

  Future<void> _deleteHabit(Habit habit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this habit?'),
        content: Text(
          'Delete “${habit.name}”? Its check-in history will also be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Color(0xFFAD6259)),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) widget.store.deleteHabit(habit.id);
  }

  @override
  Widget build(BuildContext context) {
    final habits = _visible;
    final width = MediaQuery.sizeOf(context).width;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        pageHeading(
          'Make it yours',
          'My habits',
          'Build a routine around the things that matter to you.',
          trailing: PrimaryButton(
            label: 'Add a habit',
            icon: Icons.add,
            onPressed: () => _showHabitForm(),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Find a habit...',
                  prefixIcon: Icon(
                    Icons.search,
                    size: 18,
                    color: Color(0xFF9BA69A),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 9),
            SizedBox(
              width: width < 420 ? 120 : 150,
              child: _DropdownField(
                value: _category,
                items: ['All habits', ..._categories],
                onChanged: (value) => setState(() => _category = value!),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Text(
            '${habits.length} ${habits.length == 1 ? 'habit' : 'habits'}',
            style: const TextStyle(color: Color(0xFF9AA49A), fontSize: 9),
          ),
        ),
        if (widget.store.habits.isEmpty)
          AppPanel(
            padding: const EdgeInsets.all(28),
            child: Center(
              child: Column(
                children: [
                  const Icon(
                    Icons.spa_outlined,
                    size: 30,
                    color: Color(0xFF93AC7E),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'A fresh start',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    "Add a habit you'd like to make part of your day.",
                    style: TextStyle(color: muted, fontSize: 10),
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: 'Add your first habit',
                    onPressed: () => _showHabitForm(),
                  ),
                ],
              ),
            ),
          )
        else if (habits.isEmpty)
          const AppPanel(
            child: Center(
              child: Text(
                'No habits match that search. Try a different name or category.',
                style: TextStyle(color: muted, fontSize: 11),
              ),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth < 390
                  ? 1
                  : constraints.maxWidth < 780
                  ? 2
                  : 3;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: habits.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 13,
                  mainAxisSpacing: 13,
                  mainAxisExtent: 174,
                ),
                itemBuilder: (context, index) {
                  final habit = habits[index];
                  return _HabitCard(
                    store: widget.store,
                    habit: habit,
                    onEdit: () => _showHabitForm(habit: habit),
                    onDelete: () => _deleteHabit(habit),
                  );
                },
              );
            },
          ),
      ],
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
    initialValue: value,
    isExpanded: true,
    icon: const Icon(
      Icons.keyboard_arrow_down,
      size: 17,
      color: Color(0xFF829083),
    ),
    decoration: const InputDecoration(
      contentPadding: EdgeInsets.symmetric(horizontal: 11, vertical: 11),
    ),
    style: const TextStyle(color: Color(0xFF647266), fontSize: 10),
    items: items
        .map(
          (item) => DropdownMenuItem(
            value: item,
            child: Text(item, overflow: TextOverflow.ellipsis),
          ),
        )
        .toList(),
    onChanged: onChanged,
  );
}

class _HabitCard extends StatelessWidget {
  const _HabitCard({
    required this.store,
    required this.habit,
    required this.onEdit,
    required this.onDelete,
  });

  final HabitStore store;
  final Habit habit;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final complete = store.isDoneToday(habit);
    return AppPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: habitColor(habit.color).withValues(alpha: .17),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _categoryIcon(habit.category),
                  color: habitColor(habit.color),
                  size: 18,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: onEdit,
                tooltip: 'Edit habit',
                visualDensity: VisualDensity.compact,
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 16,
                  color: Color(0xFF8F9B90),
                ),
              ),
              IconButton(
                onPressed: onDelete,
                tooltip: 'Delete habit',
                visualDensity: VisualDensity.compact,
                icon: const Icon(
                  Icons.close,
                  size: 18,
                  color: Color(0xFF9D8883),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            habit.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF405143),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${habit.category}   ·   ${habit.frequency}',
            style: const TextStyle(color: Color(0xFF97A197), fontSize: 9),
          ),
          const Spacer(),
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                size: 11,
                color: Color(0xFF8DA17D),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${store.currentStreak(habit)} day streak',
                  style: const TextStyle(color: Color(0xFF8DA17D), fontSize: 9),
                ),
              ),
              InkWell(
                onTap: () => store.toggleToday(habit.id),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: complete
                        ? const Color(0xFFEAF4EC)
                        : const Color(0xFFF5F8F3),
                    border: Border.all(
                      color: complete
                          ? const Color(0xFFD7E7D8)
                          : const Color(0xFFEDF1EB),
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    complete ? 'Completed ✓' : 'Mark as done',
                    style: TextStyle(
                      color: complete
                          ? const Color(0xFF315E3B)
                          : const Color(0xFF718070),
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Learning':
        return Icons.menu_book_outlined;
      case 'Movement':
        return Icons.directions_walk_outlined;
      case 'Mindfulness':
        return Icons.wb_sunny_outlined;
      default:
        return Icons.spa_outlined;
    }
  }
}

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key, required this.store, required this.width});

  final HabitStore store;
  final double width;

  @override
  Widget build(BuildContext context) {
    final days = store.weekDays();
    final counts = days
        .map(
          (day) => store.habits
              .where((habit) => habit.completedDates.contains(day.key))
              .length,
        )
        .toList();
    final total = counts.fold<int>(0, (sum, value) => sum + value);
    final maximum = math.max(1, counts.fold<int>(0, math.max));
    final activeKeys = <String>{};
    for (var offset = 0; offset < 7; offset++) {
      activeKeys.add(
        HabitStore.dateKey(DateTime.now().subtract(Duration(days: offset))),
      );
    }
    final activeDays = store.habits
        .expand((habit) => habit.completedDates.where(activeKeys.contains))
        .toSet()
        .length;
    final allTime = store.habits.fold<int>(
      0,
      (sum, habit) => sum + habit.completedDates.length,
    );
    final best = store.habits.isEmpty
        ? null
        : store.habits.reduce(
            (a, b) => store.currentStreak(a) >= store.currentStreak(b) ? a : b,
          );
    final twoColumns = width >= 850;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        pageHeading(
          'Notice how far you’ve come',
          'Your insights',
          "Progress isn't always loud. Here's a little reminder that it's happening.",
        ),
        if (width >= 650)
          Row(
            children: [
              Expanded(
                child: _InsightStat(
                  icon: Icons.auto_awesome,
                  tint: const Color(0xFFEAF3E8),
                  label: 'CHECK-INS THIS WEEK',
                  value: '$total',
                  note: 'little wins, all counted',
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: _InsightStat(
                  icon: Icons.access_time,
                  tint: const Color(0xFFEEF1E6),
                  label: 'ACTIVE DAYS',
                  value: '$activeDays / 7',
                  note: 'days you showed up',
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: _InsightStat(
                  icon: Icons.trending_up,
                  tint: const Color(0xFFF0F4DB),
                  label: 'ALL-TIME CHECK-INS',
                  value: '$allTime',
                  note: 'every step matters',
                ),
              ),
            ],
          )
        else
          Column(
            children: [
              _InsightStat(
                icon: Icons.auto_awesome,
                tint: const Color(0xFFEAF3E8),
                label: 'CHECK-INS THIS WEEK',
                value: '$total',
                note: 'little wins, all counted',
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _InsightStat(
                      icon: Icons.access_time,
                      tint: const Color(0xFFEEF1E6),
                      label: 'ACTIVE DAYS',
                      value: '$activeDays / 7',
                      note: 'days you showed up',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _InsightStat(
                      icon: Icons.trending_up,
                      tint: const Color(0xFFF0F4DB),
                      label: 'ALL-TIME CHECK-INS',
                      value: '$allTime',
                      note: 'every step matters',
                    ),
                  ),
                ],
              ),
            ],
          ),
        const SizedBox(height: 14),
        if (twoColumns)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 14,
                child: _WeeklyConsistency(
                  days: days,
                  counts: counts,
                  maximum: maximum,
                  today: store.todayKey(),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 8,
                child: _ReflectionPanel(store: store, best: best),
              ),
            ],
          )
        else ...[
          _WeeklyConsistency(
            days: days,
            counts: counts,
            maximum: maximum,
            today: store.todayKey(),
          ),
          const SizedBox(height: 14),
          _ReflectionPanel(store: store, best: best),
        ],
        const SizedBox(height: 14),
        _HabitHistory(store: store, days: days),
      ],
    );
  }
}

class _InsightStat extends StatelessWidget {
  const _InsightStat({
    required this.icon,
    required this.tint,
    required this.label,
    required this.value,
    required this.note,
  });

  final IconData icon;
  final Color tint;
  final String label;
  final String value;
  final String note;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 96),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: paper,
      border: Border.all(color: line),
      borderRadius: BorderRadius.circular(13),
    ),
    child: Row(
      children: [
        Container(
          width: 37,
          height: 37,
          decoration: BoxDecoration(
            color: tint,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF74936F), size: 17),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF9AA69A),
                  fontSize: 8,
                  letterSpacing: .7,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF35483A),
                  fontSize: 23,
                  height: 1,
                  letterSpacing: -.6,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                note,
                style: const TextStyle(color: Color(0xFF9DA79C), fontSize: 9),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _WeeklyConsistency extends StatelessWidget {
  const _WeeklyConsistency({
    required this.days,
    required this.counts,
    required this.maximum,
    required this.today,
  });

  final List<HabitDay> days;
  final List<int> counts;
  final int maximum;
  final String today;

  @override
  Widget build(BuildContext context) => AppPanel(
    padding: const EdgeInsets.fromLTRB(21, 20, 21, 19),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionKicker('Your week, your way'),
                  SizedBox(height: 6),
                  Text(
                    'Weekly consistency',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            _SoftTag('This week'),
          ],
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 210,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: List.generate(days.length, (index) {
              final height = counts[index] == 0
                  ? .03
                  : math.max(.09, counts[index] / maximum).toDouble();
              return Expanded(
                child: Column(
                  children: [
                    SizedBox(
                      height: 17,
                      child: Text(
                        counts[index] == 0 ? '' : '${counts[index]}',
                        style: const TextStyle(
                          color: Color(0xFF809180),
                          fontSize: 9,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        width: 45,
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F7F3),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: height,
                          widthFactor: 1,
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            decoration: BoxDecoration(
                              color: days[index].key == today
                                  ? const Color(0xFF376C45)
                                  : const Color(0xFFDCE9D9),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(7),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      days[index].label,
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      style: const TextStyle(
                        color: Color(0xFF98A398),
                        fontSize: 8,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 11),
        const Row(
          children: [
            Icon(Icons.circle, color: Color(0xFF376C45), size: 8),
            SizedBox(width: 7),
            Text(
              'Habits completed each day',
              style: TextStyle(color: Color(0xFF98A398), fontSize: 9),
            ),
          ],
        ),
      ],
    ),
  );
}

class _ReflectionPanel extends StatelessWidget {
  const _ReflectionPanel({required this.store, required this.best});

  final HabitStore store;
  final Habit? best;

  @override
  Widget build(BuildContext context) {
    final streak = best == null ? 0 : store.currentStreak(best!);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F6EC),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionKicker(
            'A moment to celebrate',
            color: Color(0xFF8B9F7C),
          ),
          const SizedBox(height: 19),
          Container(
            width: 39,
            height: 39,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFE6EFDC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.local_florist_outlined,
              color: Color(0xFF84A56D),
              size: 20,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            best?.name ?? 'Your next chapter starts here',
            style: const TextStyle(
              color: Color(0xFF526749),
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: -.3,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            best != null && streak > 0
                ? 'You have a $streak day streak. That consistency is something to be proud of.'
                : 'Pick one small thing you would like to make time for this week.',
            style: const TextStyle(
              color: Color(0xFF8A9982),
              fontSize: 10,
              height: 1.65,
            ),
          ),
          const SizedBox(height: 17),
          const Divider(color: Color(0xFFE4EBDC)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(
                width: 100,
                child: Text(
                  'YOUR LONGEST CURRENT STREAK',
                  style: TextStyle(
                    color: Color(0xFF9AA88F),
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .6,
                  ),
                ),
              ),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$streak',
                      style: const TextStyle(
                        color: Color(0xFF315E3B),
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const TextSpan(
                      text: ' days',
                      style: TextStyle(color: Color(0xFF315E3B), fontSize: 9),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HabitHistory extends StatelessWidget {
  const _HabitHistory({required this.store, required this.days});

  final HabitStore store;
  final List<HabitDay> days;

  @override
  Widget build(BuildContext context) => AppPanel(
    padding: const EdgeInsets.fromLTRB(21, 20, 21, 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionKicker('The little things add up'),
        const SizedBox(height: 6),
        const Text(
          'Habit check-in history',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        if (store.habits.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text(
              'Add a habit to start building your history.',
              style: TextStyle(color: muted, fontSize: 10),
            ),
          )
        else
          ...store.habits.map((habit) {
            final count = days
                .where((day) => habit.completedDates.contains(day.key))
                .length;
            return Container(
              constraints: const BoxConstraints(minHeight: 46),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFF0F2EE))),
              ),
              child: Row(
                children: [
                  _ColorDot(colorName: habit.color),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      habit.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF526255),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ...days.map((day) {
                    final complete = habit.completedDates.contains(day.key);
                    return Container(
                      width: 19,
                      height: 19,
                      margin: const EdgeInsets.only(left: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: complete
                            ? const Color(0xFF7BA175)
                            : Colors.white,
                        border: Border.all(
                          color: complete
                              ? const Color(0xFF7BA175)
                              : const Color(0xFFE9EEE7),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: complete
                          ? const Icon(
                              Icons.check,
                              size: 11,
                              color: Colors.white,
                            )
                          : null,
                    );
                  }),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 28,
                    child: Text(
                      '$count / 7',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: Color(0xFF9BA69B),
                        fontSize: 9,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    ),
  );
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.store,
    required this.onLogout,
  });

  final HabitStore store;
  final VoidCallback onLogout;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _name;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.store.name);
    _name.addListener(() {
      if (_saved) setState(() => _saved = false);
    });
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      pageHeading('Make your space feel right', 'Settings', ''),
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Column(
          children: [
            _SettingsPanel(
              icon: Icons.person_outline,
              title: 'Your profile',
              subtitle: 'What should we call you?',
              child: Padding(
                padding: const EdgeInsets.only(left: 49, top: 18),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _FieldLabel('Display name'),
                      TextField(
                        controller: _name,
                        maxLength: 24,
                        decoration: const InputDecoration(
                          hintText: 'Your name',
                          counterText: '',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (_saved)
                            const Text(
                              'Changes saved',
                              style: TextStyle(
                                color: Color(0xFF62936B),
                                fontSize: 10,
                              ),
                            ),
                          PrimaryButton(
                            label: 'Save changes',
                            onPressed: () {
                              widget.store.saveName(_name.text);
                              _name.text = widget.store.name;
                              setState(() => _saved = true);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 13),
            _SettingsPanel(
              icon: Icons.calendar_view_week_outlined,
              title: 'How your week starts',
              subtitle: 'Choose the first day shown in your weekly view.',
              child: Padding(
                padding: const EdgeInsets.only(left: 49, top: 18),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Start on Monday',
                            style: TextStyle(
                              color: Color(0xFF59685A),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Turn off to start your week on Sunday.',
                            style: TextStyle(
                              color: Color(0xFF9DA69D),
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Semantics(
                      label: 'Start week on Monday',
                      hint: 'Turn off to start your week on Sunday.',
                      child: Switch(
                        value: widget.store.weekStartsMonday,
                        onChanged: widget.store.setWeekStartsMonday,
                        activeTrackColor: const Color(0xFF285C39),
                        thumbColor: WidgetStateProperty.all(Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 13),
            _SettingsPanel(
              icon: Icons.logout,
              blush: true,
              title: 'Sign out',
              subtitle: 'End your current session on this device.',
              child: Padding(
                padding: const EdgeInsets.only(left: 49, top: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton(
                    onPressed: widget.onLogout,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFAD6259),
                      side: const BorderSide(color: Color(0xFFEDDEDA)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: const TextStyle(fontSize: 10),
                    ),
                    child: const Text('Log out'),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 25),
            const Text(
              'DAILY HABIT TRACKER  ·  KEEP GROWING AT YOUR OWN PACE',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFA7AFA5),
                fontSize: 8,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
    this.blush = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;
  final bool blush;

  @override
  Widget build(BuildContext context) => AppPanel(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 37,
              height: 37,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: blush
                    ? const Color(0xFFF8EFEC)
                    : const Color(0xFFEAF3E8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 19,
                color: blush
                    ? const Color(0xFFBB8172)
                    : const Color(0xFF73916D),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF405343),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF99A399),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        child,
      ],
    ),
  );
}
