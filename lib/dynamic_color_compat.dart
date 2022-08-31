library dynamic_color_compat;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:material_color_utilities/material_color_utilities.dart';
import 'package:palette_from_wallpaper/palette_from_wallpaper.dart';

CorePalette _defaultCompatBuilder(PlatformPalette p) {
  return CorePalette.of(p.primaryColor.value);
}

/// Runs the app with an injected [InheritedDynamicColor] at the root of the tree, so
/// that an [InheritedDynamicColor] is always available.
void runDynamicallyThemedApp(
  Widget home, {
  required CorePalette Function() fallback,
  CorePalette Function(PlatformPalette) compatBuilder = _defaultCompatBuilder,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  final corePalette = await DynamicColorPlugin.getCorePalette();
  if (corePalette != null) {
    runApp(InheritedDynamicColor(corePalette: corePalette, child: home));
  }
  try {
    final platformPalette = await PaletteFromWallpaper.getPalette(nullOk: true);
    if (platformPalette == null) {
      return runApp(
        InheritedDynamicColor(corePalette: fallback(), child: home),
      );
    }
    return runApp(
      _PaletteApp(
        initialPalette: platformPalette,
        compatBuilder: compatBuilder,
        home: home,
      ),
    );
  } catch (e) {
    return runApp(InheritedDynamicColor(corePalette: fallback(), child: home));
  }
}

class _PaletteApp extends StatefulWidget {
  final Widget home;
  final PlatformPalette initialPalette;
  final CorePalette Function(PlatformPalette) compatBuilder;
  const _PaletteApp({
    Key? key,
    required this.home,
    required this.initialPalette,
    required this.compatBuilder,
  }) : super(key: key);

  @override
  _PaletteAppState createState() => _PaletteAppState();
}

class _PaletteAppState extends State<_PaletteApp> {
  late PlatformPalette palette;
  StreamSubscription? subscription;
  @override
  void initState() {
    super.initState();
    palette = widget.initialPalette;
    _initSubscription();
  }

  @override
  void dispose() {
    subscription?.cancel();
    super.dispose();
  }

  void _onUpdate(PlatformPalette palette) {
    if (!mounted) {
      return;
    }
    if (palette == this.palette) {
      return;
    }
    setState(() => this.palette = palette);
  }

  void _initSubscription() {
    if (!mounted) {
      return;
    }
    subscription = PaletteFromWallpaper.paletteUpdates
        .cast<PlatformPalette?>()
        .where((event) => event != null)
        .cast<PlatformPalette>()
        .listen(_onUpdate);
  }

  @override
  Widget build(BuildContext context) {
    return InheritedDynamicColor(
      corePalette: widget.compatBuilder(palette),
      child: widget.home,
    );
  }
}

class InheritedDynamicColor extends InheritedWidget {
  final CorePalette corePalette;

  const InheritedDynamicColor({
    Key? key,
    required this.corePalette,
    required Widget child,
  }) : super(
          key: key,
          child: child,
        );

  static CorePalette of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<InheritedDynamicColor>()!
      .corePalette;

  @override
  bool updateShouldNotify(InheritedDynamicColor oldWidget) =>
      corePalette != oldWidget.corePalette;
}

extension ContextE on BuildContext {
  CorePalette get dynamicColor => InheritedDynamicColor.of(this);
}
