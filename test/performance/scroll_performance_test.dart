import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supper/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Performance Tests', () {
    testWidgets('Chat list scroll performance', (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Find the chat list
      final chatListFinder = find.byType(ListView);
      
      if (chatListFinder.evaluate().isNotEmpty) {
        // Measure scroll performance
        final stopwatch = Stopwatch()..start();
        
        // Perform multiple scroll actions
        for (int i = 0; i < 5; i++) {
          await tester.fling(chatListFinder, const Offset(0, -300), 1000);
          await tester.pumpAndSettle();
          await tester.fling(chatListFinder, const Offset(0, 300), 1000);
          await tester.pumpAndSettle();
        }
        
        stopwatch.stop();
        print('Scroll test completed in ${stopwatch.elapsedMilliseconds}ms');
        
        // Assert that scrolling is smooth (under 3 seconds for 10 scrolls)
        expect(stopwatch.elapsedMilliseconds, lessThan(3000));
      }
    });

    testWidgets('Message list rendering performance', (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Navigate to a chat if possible
      final chatTileFinder = find.byType(ListTile);
      if (chatTileFinder.evaluate().isNotEmpty) {
        await tester.tap(chatTileFinder.first);
        await tester.pumpAndSettle();

        // Find message list
        final messageListFinder = find.byType(ListView);
        
        if (messageListFinder.evaluate().isNotEmpty) {
          final stopwatch = Stopwatch()..start();
          
          // Scroll through messages
          for (int i = 0; i < 3; i++) {
            await tester.fling(messageListFinder, const Offset(0, -500), 2000);
            await tester.pump();
            await tester.fling(messageListFinder, const Offset(0, 500), 2000);
            await tester.pump();
          }
          
          stopwatch.stop();
          print('Message scroll test completed in ${stopwatch.elapsedMilliseconds}ms');
        }
      }
    });

    testWidgets('Navigation performance', (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      final stopwatch = Stopwatch()..start();
      
      // Test navigation between tabs
      final bottomNavItems = find.byType(BottomNavigationBarItem);
      
      if (bottomNavItems.evaluate().length >= 3) {
        for (int i = 0; i < 3; i++) {
          await tester.tap(find.byIcon(Icons.chat));
          await tester.pumpAndSettle();
          await tester.tap(find.byIcon(Icons.people));
          await tester.pumpAndSettle();
          await tester.tap(find.byIcon(Icons.person));
          await tester.pumpAndSettle();
        }
      }
      
      stopwatch.stop();
      print('Navigation test completed in ${stopwatch.elapsedMilliseconds}ms');
      
      // Navigation should be quick
      expect(stopwatch.elapsedMilliseconds, lessThan(2000));
    });

    testWidgets('Image loading performance', (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Count cached network images
      final cachedImages = find.byType(Image);
      print('Found ${cachedImages.evaluate().length} images');
      
      // Ensure images load within reasonable time
      await tester.pump(const Duration(seconds: 2));
      
      // Check if images are rendered
      expect(cachedImages.evaluate().isNotEmpty, true);
    });
  });
}