import 'package:dairy_app/features/auth/presentation/widgets/guest_sign_up.dart';
import 'package:dairy_app/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// DearCocoa demo walkthrough (used by the GitHub Actions emulator job to
/// produce the client demo screenshots + video).
///
/// The host side captures frames with a blind `adb screencap` loop and a
/// `screenrecord` video; this test prints a `DEMO_SCREEN: <name>` marker on
/// logcat right before each step, so frames and markers can be aligned after
/// the run. Interactions are defensive: a failing optional step is logged and
/// skipped instead of killing the walkthrough.
Future<void> main() async {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('DearCocoa demo walkthrough', (tester) async {
    app.main();

    // ------------------------------------------------------ 01 welcome
    await _hold(tester, seconds: 3);
    _marker('01-welcome');
    await _hold(tester, seconds: 3);

    // Welcome auto-navigates to the auth page after ~2s (real timer).
    await _untilVisible(tester, find.byType(GuestSignUp), maxSec: 25);
    _marker('02-auth-guest');
    await _hold(tester, seconds: 3);

    // -------------------------------------------------- guest sign in
    await tester.tap(find.byType(GuestSignUp));
    await _untilVisible(tester, find.byType(FloatingActionButton), maxSec: 40);
    _marker('03-journal-empty');
    await _hold(tester, seconds: 4);

    // ------------------------------------- DearCocoa pane on the home
    _marker('04-journal-panes');
    await _hold(tester, seconds: 3);

    // the DearCocoa pane is the LAST page of the dashboard carousel:
    // swipe left until the hub button is reachable
    try {
      final pageView = find.byType(PageView);
      if (pageView.evaluate().isNotEmpty) {
        await tester.dragUntilVisible(
          find.text('Open DearCocoa hub'),
          pageView.first,
          const Offset(-500, 0),
          maxIteration: 5,
        );
        await tester.pump(const Duration(milliseconds: 600));
        _log('carousel reached DearCocoa pane');
      }
    } catch (e) {
      _log('carousel swipe skipped: $e');
    }

    // ------------------------------------- open DearCocoa hub (sign in)
    final hubButton = find.text('Open DearCocoa hub');
    if (hubButton.evaluate().isNotEmpty) {
      await tester.tap(hubButton);
      // first run: DearCocoaSignInPage with prefilled Alex Rivera
      await _untilVisible(tester, find.text('Demo accounts'), maxSec: 30);
      _marker('05-dearcocoa-sign-in');
      await _hold(tester, seconds: 4);

      final signIn = find.text('Sign in');
      if (signIn.evaluate().isNotEmpty) {
        await tester.tap(signIn.last);
      }
      // wait for the hub to appear after Supabase auth + cloud journal pull
      await _untilVisible(tester, find.text('Mood Tracker'), maxSec: 45);
      _marker('06-hub');
      await _hold(tester, seconds: 5);
    }

    // --------------------------------------------- mood tracker + check-in
    final moodCard = find.text('Mood Tracker').first;
    if (moodCard.evaluate().isNotEmpty) {
      await tester.tap(moodCard);
      await _untilVisible(tester, find.text('Save check-in'), maxSec: 30);
      _marker('07-mood-tracker');
      await _hold(tester, seconds: 4);

      try {
        await tester.tap(find
            .byIcon(Icons.sentiment_satisfied_alt_rounded)
            .first);
        await tester.pump();
        await _enterIntoLabeled(
            tester, 'Add a short note (optional)',
            'Demo day: felt calm and productive after the run.');
        await tester.tap(find.text('Save check-in'));
        await _hold(tester, seconds: 3);
      } catch (e) {
        _log('mood check-in step skipped: $e');
      }
      _marker('08-mood-logged');
      await _hold(tester, seconds: 3);
      await _back(tester);
      await _hold(tester, seconds: 2);
    }

    // ----------------------------------------------------- community
    final communityCard = find.text('Community Spaces').first;
    if (communityCard.evaluate().isNotEmpty) {
      await tester.tap(communityCard);
      // the feed shows posts, not space names: wait for a likeable post card
      await _untilVisible(
          tester, find.byIcon(Icons.favorite_border_rounded), maxSec: 30);
      _marker('09-community-feed');
      await _hold(tester, seconds: 4);

      // like the first likeable post
      try {
        final likeIcon = find.byIcon(Icons.favorite_border_rounded);
        if (likeIcon.evaluate().isNotEmpty) {
          await tester.tap(likeIcon.first);
          await _hold(tester, seconds: 2);
        }
      } catch (e) {
        _log('like step skipped: $e');
      }
      _marker('10-community-liked');
      await _hold(tester, seconds: 2);

      // publish a post from the FAB bottom sheet
      try {
        final fab = find.byType(FloatingActionButton);
        if (fab.evaluate().isNotEmpty) {
          await tester.tap(fab.first);
          await _untilVisible(
              tester, find.text('Share with the community...'), maxSec: 20);
          _marker('11-community-compose');
          await _hold(tester, seconds: 2);
          await _enterIntoLabeled(tester, 'Share with the community...',
              'Started the 6am experiment after reading this space. Day 1, feeling good.');
          await _hold(tester, seconds: 1);
          await tester.tap(find.text('Publish'));
          await _hold(tester, seconds: 3);
        }
      } catch (e) {
        _log('publish post step skipped: $e');
      }
      _marker('12-community-posted');
      await _hold(tester, seconds: 3);
      await _back(tester);
      await _hold(tester, seconds: 2);
    }

    // ------------------------------------------------- group chat
    final chatCard = find.text('Group Conversations').first;
    if (chatCard.evaluate().isNotEmpty) {
      await tester.tap(chatCard);
      await _untilVisible(tester, find.text('Wellness Wins'), maxSec: 30);
      _marker('13-chat-rooms');
      await _hold(tester, seconds: 4);

      await tester.tap(find.text('Wellness Wins').first);
      await _untilVisible(tester, find.byIcon(Icons.send_rounded), maxSec: 30);
      _marker('14-chat-room');
      await _hold(tester, seconds: 4);

      try {
        final field = find.byType(TextField).last;
        await tester.enterText(field,
            'This message is being sent live during the client demo. Realtime!');
        await tester.tap(find.byIcon(Icons.send_rounded));
        await _hold(tester, seconds: 4);
      } catch (e) {
        _log('chat send step skipped: $e');
      }
      _marker('15-chat-message-sent');
      await _hold(tester, seconds: 3);
      await _back(tester);
      await _hold(tester, seconds: 2);
      await _back(tester);
      await _hold(tester, seconds: 2);
    }

    // ------------------------------------------------------- events
    final eventsCard = find.text('Virtual Events').first;
    if (eventsCard.evaluate().isNotEmpty) {
      await tester.tap(eventsCard);
      await _untilVisible(
          tester, find.textContaining('Guided Morning Meditation'), maxSec: 30);
      _marker('16-events');
      await _hold(tester, seconds: 4);

      try {
        await tester.tap(find.text('Going').first);
        await _hold(tester, seconds: 3);
      } catch (e) {
        _log('rsvp step skipped: $e');
      }
      _marker('17-event-rsvp');
      await _hold(tester, seconds: 3);
      await _back(tester);
      await _hold(tester, seconds: 2);
    }

    // ---------------------------------------------------- reflections
    final reflectionsCard = find.text('AI Reflections').first;
    if (reflectionsCard.evaluate().isNotEmpty) {
      await tester.tap(reflectionsCard);
      await _untilVisible(tester, find.byType(TextField), maxSec: 30);
      _marker('18-reflections');
      await _hold(tester, seconds: 4);
      await _back(tester);
      await _hold(tester, seconds: 2);
    }

    // back to the home journal, which is now synced with the cloud entries
    await _back(tester);
    await _hold(tester, seconds: 2);

    // swipe the carousel back to the first (journal) pane
    try {
      final pageView = find.byType(PageView);
      if (pageView.evaluate().isNotEmpty) {
        for (var i = 0; i < 4; i++) {
          await tester.fling(pageView.first, const Offset(600, 0), 1000);
          await Future<void>.delayed(const Duration(milliseconds: 500));
          await tester.pump(const Duration(milliseconds: 300));
        }
      }
    } catch (e) {
      _log('carousel swipe back skipped: $e');
    }

    // ------------------------------- home journal now synced with cloud
    _marker('19-journal-synced');
    await _hold(tester, seconds: 4);

    // -------------------------------------------- journal with history
    _marker('20-journal-history');
    await _hold(tester, seconds: 4);

    _log('walkthrough complete');
  });
}

// ---------------------------------------------------------------- helpers

void _log(String message) => debugPrint('DEMO_LOG: $message');

/// Marker with device epoch (ms): the aligner maps it to the screencap
/// frames captured on the host (emulator clock is host-synced).
void _marker(String name) =>
    debugPrint('DEMO_SCREEN|${DateTime.now().toUtc().millisecondsSinceEpoch}|$name');

/// Real-time hold: gives the host-side screencap loop time to capture the
/// current screen cleanly (integration tests run on real wall-clock).
Future<void> _hold(WidgetTester tester, {int seconds = 2}) async {
  await tester.pump(const Duration(milliseconds: 100));
  await Future<void>.delayed(Duration(seconds: seconds));
  await tester.pump(const Duration(milliseconds: 100));
}

/// Pumps until [finder] finds widgets, mixing real delays so that async
/// blocs/repositories (Supabase, sqlite) can settle.
Future<void> _untilVisible(
  WidgetTester tester,
  Finder finder, {
  int maxSec = 20,
}) async {
  final end = DateTime.now().add(Duration(seconds: maxSec));
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finder.evaluate().isNotEmpty) return;
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }
  // final check for logging purposes only
  _log('finder not found within ${maxSec}s: $finder');
}

/// Types into the TextField whose decoration label/hint matches [label].
Future<void> _enterIntoLabeled(
  WidgetTester tester,
  String label,
  String text,
) async {
  final field = find.widgetWithText(TextField, label);
  if (field.evaluate().isEmpty) {
    _log('labeled field not found: $label');
    return;
  }
  await tester.tap(field.first);
  await tester.pump();
  await tester.enterText(field.first, text);
  await tester.pump();
}

/// Pops the top route via the root navigator (BackButton taps can miss when
/// the button renders disabled during route transitions).
Future<void> _back(WidgetTester tester) async {
  final navigatorState =
      tester.state<NavigatorState>(find.byType(Navigator).first);
  if (navigatorState.canPop()) {
    navigatorState.pop();
  }
  await tester.pump(const Duration(milliseconds: 400));
}
