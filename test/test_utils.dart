import 'package:flutter/material.dart';

// ── Wrappers ──────────────────────────────────────────────────────────────

/// Wraps [child] in a [MaterialApp] + [Scaffold] for widget tests.
Widget testApp(Widget child) => MaterialApp(home: Scaffold(body: child));

/// Redirects [FlutterError.onError] for the duration of [body], collecting
/// all errors instead of failing the test. Returns the captured errors so
/// the caller can assert on their content.
///
/// Use this when a widget is expected to emit layout or assertion errors
/// during build, and the test needs to inspect those errors rather than
/// let them fail the harness.
Future<List<FlutterErrorDetails>> captureFlutterErrors(
  Future<void> Function() body,
) async {
  final captured = <FlutterErrorDetails>[];
  final previous = FlutterError.onError;
  FlutterError.onError = (details) => captured.add(details);
  try {
    await body();
  } finally {
    FlutterError.onError = previous;
  }
  return captured;
}

// ── Shared test constants ─────────────────────────────────────────────────

/// Canonical canvas size for painter / layout tests across the suite.
///
/// All chart test files use the same size so that painters produce
/// directly-comparable layouts and assertions on chart area dimensions
/// don't drift between files. Prefer this over a file-local `_size`.
const Size kChartTestSize = Size(400, 300);
