import 'package:flutter/material.dart';

/// Responsive layout utility for adaptive UI
class ResponsiveLayout {
  // Breakpoints for different screen sizes
  static const double mobileMaxWidth = 600;
  static const double tabletMaxWidth = 1200;

  /// Check if the current device is mobile (phone)
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileMaxWidth;
  }

  /// Check if the current device is tablet (iPad)
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileMaxWidth && width < tabletMaxWidth;
  }

  /// Check if the current device is desktop (macOS, large tablets)
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletMaxWidth;
  }

  /// Check if split view should be enabled (tablet or desktop)
  static bool shouldUseSplitView(BuildContext context) {
    return !isMobile(context);
  }

  /// Get the appropriate width for the master pane in split view
  static double getMasterPaneWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (isDesktop(context)) {
      return 200; // Narrower fixed width for desktop (was 400)
    } else if (isTablet(context)) {
      return screenWidth * 0.25; // 25% of screen width for tablet (was 40%)
    }
    return screenWidth; // Full width for mobile
  }
}

/// Adaptive scaffold that automatically switches between single-pane and split-pane layouts
class AdaptiveScaffold extends StatelessWidget {
  final Widget masterPane;
  final Widget? detailPane;
  final String title;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Color? backgroundColor;

  const AdaptiveScaffold({
    super.key,
    required this.masterPane,
    this.detailPane,
    required this.title,
    this.actions,
    this.floatingActionButton,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final useSplitView = ResponsiveLayout.shouldUseSplitView(context);

    if (useSplitView && detailPane != null) {
      // Split view for tablet and desktop
      return Scaffold(
        backgroundColor: backgroundColor ?? Colors.black,
        appBar: AppBar(
          title: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  width: 32,
                  height: 32,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF00FF00),
                    fontFamily: 'Courier',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          backgroundColor: const Color(0xFF1A1A1A),
          automaticallyImplyLeading: false,
          actions: actions,
        ),
        body: Row(
          children: [
            // Master pane (left side)
            SizedBox(
              width: ResponsiveLayout.getMasterPaneWidth(context),
              child: Container(
                decoration: const BoxDecoration(
                  border: Border(
                    right: BorderSide(
                      color: Color(0xFF00FF00),
                      width: 1,
                    ),
                  ),
                ),
                child: masterPane,
              ),
            ),
            // Detail pane (right side)
            Expanded(
              child: detailPane!,
            ),
          ],
        ),
        floatingActionButton: floatingActionButton,
      );
    } else {
      // Single pane view for mobile or when no detail pane
      return Scaffold(
        backgroundColor: backgroundColor ?? Colors.black,
        appBar: AppBar(
          title: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  width: 32,
                  height: 32,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF00FF00),
                    fontFamily: 'Courier',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          backgroundColor: const Color(0xFF1A1A1A),
          automaticallyImplyLeading: false,
          actions: actions,
        ),
        body: masterPane,
        floatingActionButton: floatingActionButton,
      );
    }
  }
}

