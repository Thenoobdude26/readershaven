import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readershaven/auth.dart';

// ─────────────────────────────────────────────────────────────
// Widget Tests — Login / Sign Up Page
// These test UI behaviour without needing a Supabase connection
// because validation runs before any network call is made
// ─────────────────────────────────────────────────────────────

void main() {
  group('LoginSignupPage', () {
    testWidgets('renders sign in form by default', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginSignupPage()),
      );

      expect(find.text('SIGN IN'), findsOneWidget);
      expect(find.text('Sign In'), findsWidgets);
    });

    testWidgets('shows error when submitting empty sign in form', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginSignupPage()),
      );

      // Tap SIGN IN without filling in any fields
      await tester.tap(find.text('SIGN IN'));
      await tester.pump();

      expect(find.text('Enter your email'), findsOneWidget);
      expect(find.text('Enter your password'), findsOneWidget);
    });

    testWidgets('shows error for invalid email format', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginSignupPage()),
      );

      // Enter invalid email
      await tester.enterText(
        find.byType(TextFormField).first,
        'notanemail',
      );
      await tester.tap(find.text('SIGN IN'));
      await tester.pump();

      expect(find.text('Enter a valid email'), findsOneWidget);
    });

    testWidgets('shows error for short password', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginSignupPage()),
      );

      // Enter valid email
      await tester.enterText(
        find.byType(TextFormField).first,
        'test@email.com',
      );
      // Enter short password
      await tester.enterText(
        find.byType(TextFormField).at(1),
        '123',
      );
      await tester.tap(find.text('SIGN IN'));
      await tester.pump();

      expect(find.text('At least 6 characters'), findsOneWidget);
    });

    testWidgets('switches to sign up form when Sign Up is tapped', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginSignupPage()),
      );

      // Tap Sign Up toggle
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      // Should now show CREATE ACCOUNT button and username field
      expect(find.text('CREATE ACCOUNT'), findsOneWidget);
    });

    testWidgets('sign up form shows password mismatch error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginSignupPage()),
      );

      // Switch to sign up
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);

      // Username
      await tester.enterText(fields.at(0), 'testuser');
      // Email
      await tester.enterText(fields.at(1), 'test@email.com');
      // Password
      await tester.enterText(fields.at(2), 'password123');
      // Confirm password — different
      await tester.enterText(fields.at(3), 'differentpassword');

      await tester.tap(find.text('CREATE ACCOUNT'));
      await tester.pump();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('sign up requires username', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginSignupPage()),
      );

      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      // Submit without filling username
      await tester.tap(find.text('CREATE ACCOUNT'));
      await tester.pump();

      expect(find.text('Enter a username'), findsOneWidget);
    });
  });
}