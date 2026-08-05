#!/usr/bin/env bash
set -Eeuo pipefail

# 1) Brighter theme
THEME="lib/core/theme/app_theme.dart"
if [[ -f "$THEME" ]]; then
  cp -a "$THEME" "${THEME}.bak.$(date +%Y%m%d_%H%M%S)"
  cat > "$THEME" << 'DART'
import 'package:flutter/material.dart';

class AppTheme {
  // Brighter accent palette
  static const Color primaryColor = Color(0xFFFFB300); // vivid amber
  static const Color gainColor = Color(0xFF00C853);    // bright green
  static const Color lossColor = Color(0xFFFF1744);    // bright red

  static ThemeData light() {
    final cs = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
      primary: primaryColor,
    );
    return ThemeData(
      colorScheme: cs,
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF9FAFB),
      appBarTheme: AppBarTheme(
        backgroundColor: cs.surface,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        elevation: 1.5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: Colors.black87,
        titleTextStyle: TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }

  static ThemeData dark() {
    final cs = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
      primary: primaryColor,
    );
    return ThemeData(
      colorScheme: cs,
      useMaterial3: true,
      cardTheme: CardTheme(
        elevation: 1.5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
DART
  echo "Brighter theme patched: $THEME"
fi

# 2) Floating quick-action FAB on Home
HOME="lib/features/home/presentation/home_screen.dart"
if [[ -f "$HOME" ]]; then
  cp -a "$HOME" "${HOME}.bak.$(date +%Y%m%d_%H%M%S)"
  python3 - << 'PY' "$HOME"
import io, re, sys
p=sys.argv[1]; s=io.open(p,'r',encoding='utf-8').read()
if "quick_actions_screen.dart" not in s:
  s=s.replace(
    "import 'package:mse_market_connect/features/home/presentation/quick_actions_screen.dart';",
    "import 'package:mse_market_connect/features/home/presentation/quick_actions_screen.dart';"
  )
# Add a pulsing FAB if not present
if "floatingActionButton:" not in s:
  s=re.sub(
    r"Widget build\(BuildContext context\)\s*\{\s*return\s+Scaffold\(",
    "Widget build(BuildContext context) {\n    return Scaffold(",
    s, count=1
  )
  s=s.replace(
    "return Scaffold(",
    """return Scaffold(
      floatingActionButton: _PulsingFab(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const QuickActionsScreen()),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,""",
    1
  )
  # append _PulsingFab
  if "_PulsingFab" not in s:
    s += """

class _PulsingFab extends StatefulWidget {
  final VoidCallback onTap;
  const _PulsingFab({required this.onTap});
  @override
  State<_PulsingFab> createState() => _PulsingFabState();
}
class _PulsingFabState extends State<_PulsingFab> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
  @override void dispose(){_c.dispose(); super.dispose();}
  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.94, end: 1.04).animate(
        CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
      child: FloatingActionButton.extended(
        heroTag: 'quick-fab',
        onPressed: widget.onTap,
        icon: const Icon(Icons.flash_on_rounded),
        label: const Text('Quick'),
      ),
    );
  }
}
"""
io.open(p,'w',encoding='utf-8',newline='').write(s)
print("Home FAB patched:", p)
PY
else:
  echo "Home screen not found; skipped FAB"
fi

# 3) Pulsing Upgrade button overlay in main nav shell
SHELL="lib/shared/widgets/main_nav_shell.dart"
if [[ -f "$SHELL" ]]; then
  cp -a "$SHELL" "${SHELL}.bak.$(date +%Y%m%d_%H%M%S)"
  python3 - << 'PY' "$SHELL"
import io, re, sys
p=sys.argv[1]; s=io.open(p,'r',encoding='utf-8').read()
if "upgrade_screen.dart" not in s:
  s=s.replace(
    "import 'package:mse_market_connect/shared/widgets/company_logo.dart';",
    "import 'package:mse_market_connect/shared/widgets/company_logo.dart';\nimport 'package:mse_market_connect/features/profile/presentation/upgrade_screen.dart';"
  )
# Wrap root body with Stack and overlay the button if not already
if "_UpgradePulseButton" not in s:
  s=re.sub(r"body:\s*([^\n]+),", r"body: Stack(children:[\1, const _UpgradePulseButton(),]),", s, count=1)
  s += """

class _UpgradePulseButton extends StatefulWidget {
  const _UpgradePulseButton();
  @override
  State<_UpgradePulseButton> createState() => _UpgradePulseButtonState();
}
class _UpgradePulseButtonState extends State<_UpgradePulseButton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 1600))..repeat(reverse: true);
  @override void dispose(){_c.dispose(); super.dispose();}
  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 16, bottom: 22,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.96, end: 1.06).animate(
          CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
        child: ElevatedButton.icon(
          icon: const Icon(Icons.workspace_premium),
          label: const Text('Upgrade'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFB300),
            foregroundColor: Colors.black,
            elevation: 6,
            shadowColor: Colors.amber.withOpacity(0.5),
          ),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const UpgradeScreen())),
        ),
      ),
    );
  }
}
"""
io.open(p,'w',encoding='utf-8',newline='').write(s)
print("Upgrade overlay patched:", p)
PY
else
  echo "Nav shell not found; skipped upgrade overlay"
fi

echo "UX brighten + animations applied."
