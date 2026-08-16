import 'package:estodo/app/widgets/animated_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the destination after the splash sequence completes',
      (tester) async {
    await tester.pumpWidget(
      const AnimatedSplashScreen(
        ready: true,
        child: Material(child: Center(child: Text('Ana ekran'))),
      ),
    );

    await tester.pump(const Duration(milliseconds: 1400));
    await tester.pump(const Duration(milliseconds: 750));
    await tester.pump();

    expect(find.text('Ana ekran'), findsOneWidget);
  });
}
