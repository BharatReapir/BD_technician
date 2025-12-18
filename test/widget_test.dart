import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bharatapp/main.dart';

void main() {
  testWidgets('Landing page smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const BharatDoorstepApp());

    // Verify that landing page elements are present
    expect(find.text('Bharat Doorstep'), findsOneWidget);
    expect(find.text('Fast. Trusted. Doorstep Repairs.'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.text('User App'), findsOneWidget);
    expect(find.text('Technician App'), findsOneWidget);
    expect(find.text('Website'), findsOneWidget);
    expect(find.text('Admin Panel'), findsOneWidget);
  });

  testWidgets('Navigation to Sign Up page', (WidgetTester tester) async {
    await tester.pumpWidget(const BharatDoorstepApp());

    // Tap the Get Started button
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    // Verify that Sign Up page is displayed
    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text('Join thousands of happy customers'), findsOneWidget);
    expect(find.text('Full Name'), findsOneWidget);
    expect(find.text('Mobile Number'), findsOneWidget);
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Select City'), findsOneWidget);
  });

  testWidgets('Sign Up form validation', (WidgetTester tester) async {
    await tester.pumpWidget(const BharatDoorstepApp());

    // Navigate to Sign Up page
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    // Find text fields
    final nameField = find.widgetWithText(TextField, 'Enter your full name');
    final mobileField = find.widgetWithText(TextField, 'Enter 10-digit mobile number');
    final emailField = find.widgetWithText(TextField, 'your.email@example.com');

    // Enter test data
    await tester.enterText(nameField, 'Test User');
    await tester.enterText(mobileField, '9876543210');
    await tester.enterText(emailField, 'test@example.com');

    // Verify text entry
    expect(find.text('Test User'), findsOneWidget);
    expect(find.text('9876543210'), findsOneWidget);
    expect(find.text('test@example.com'), findsOneWidget);
  });

  testWidgets('Navigation to OTP page', (WidgetTester tester) async {
    await tester.pumpWidget(const BharatDoorstepApp());

    // Navigate to Sign Up page
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    // Fill form
    await tester.enterText(
      find.widgetWithText(TextField, 'Enter your full name'),
      'Test User',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Enter 10-digit mobile number'),
      '9876543210',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'your.email@example.com'),
      'test@example.com',
    );

    // Tap Create Account button
    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle();

    // Verify OTP page is displayed
    expect(find.text('Enter OTP'), findsOneWidget);
    expect(find.text('We\'ve sent a 6-digit OTP to 9876543210'), findsOneWidget);
    expect(find.text('Verify & Continue'), findsOneWidget);
    expect(find.text('Change Number'), findsOneWidget);
  });

  testWidgets('OTP input fields test', (WidgetTester tester) async {
    await tester.pumpWidget(const BharatDoorstepApp());

    // Navigate to OTP page
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    
    await tester.enterText(
      find.widgetWithText(TextField, 'Enter 10-digit mobile number'),
      '9876543210',
    );
    
    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle();

    // Verify 6 OTP input fields exist
    final otpFields = find.byType(TextField);
    expect(otpFields, findsNWidgets(6));
  });

  testWidgets('Navigation to Home page after OTP', (WidgetTester tester) async {
    await tester.pumpWidget(const BharatDoorstepApp());

    // Navigate through Sign Up and OTP pages
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    
    await tester.enterText(
      find.widgetWithText(TextField, 'Enter 10-digit mobile number'),
      '9876543210',
    );
    
    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle();

    // Tap Verify & Continue button
    await tester.tap(find.text('Verify & Continue'));
    await tester.pumpAndSettle();

    // Verify Home page is displayed
    expect(find.text('Bharat Doorstep'), findsOneWidget);
    expect(find.text('Your Trusted Service Partner'), findsOneWidget);
    expect(find.text('All Services'), findsOneWidget);
  });

  testWidgets('Bottom navigation bar test', (WidgetTester tester) async {
    await tester.pumpWidget(const BharatDoorstepApp());

    // Navigate to Home page
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Enter 10-digit mobile number'),
      '9876543210',
    );
    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Verify & Continue'));
    await tester.pumpAndSettle();

    // Verify bottom navigation items
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Bookings'), findsOneWidget);
    expect(find.text('Wallet'), findsOneWidget);
    expect(find.text('Support'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    // Test navigation to Bookings
    await tester.tap(find.text('Bookings'));
    await tester.pumpAndSettle();
    expect(find.text('Bookings Page'), findsOneWidget);

    // Test navigation to Wallet
    await tester.tap(find.text('Wallet'));
    await tester.pumpAndSettle();
    expect(find.text('Wallet Page'), findsOneWidget);

    // Test navigation to Support
    await tester.tap(find.text('Support'));
    await tester.pumpAndSettle();
    expect(find.text('Support Page'), findsOneWidget);

    // Test navigation to Profile
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Profile Page'), findsOneWidget);
  });

  testWidgets('Home page services grid test', (WidgetTester tester) async {
    await tester.pumpWidget(const BharatDoorstepApp());

    // Navigate to Home page
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Enter 10-digit mobile number'),
      '9876543210',
    );
    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Verify & Continue'));
    await tester.pumpAndSettle();

    // Verify service items
    expect(find.text('AC Repair'), findsOneWidget);
    expect(find.text('TV Repair'), findsOneWidget);
    expect(find.text('Refrigerator'), findsOneWidget);
    expect(find.text('Washing Machine'), findsOneWidget);
    expect(find.text('Electrician'), findsOneWidget);
    expect(find.text('Plumber'), findsOneWidget);
    expect(find.text('Cleaning'), findsOneWidget);
    expect(find.text('More'), findsOneWidget);
  });

  testWidgets('Home page offers carousel test', (WidgetTester tester) async {
    await tester.pumpWidget(const BharatDoorstepApp());

    // Navigate to Home page
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Enter 10-digit mobile number'),
      '9876543210',
    );
    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Verify & Continue'));
    await tester.pumpAndSettle();

    // Verify offer cards
    expect(find.text('First Time Users'), findsOneWidget);
    expect(find.text('40% OFF'), findsOneWidget);
    expect(find.text('AC Service Special'), findsOneWidget);
    expect(find.text('₹299 Only'), findsOneWidget);
    expect(find.text('Weekend Deal'), findsOneWidget);
    expect(find.text('Flat ₹200 OFF'), findsOneWidget);
  });

  testWidgets('Notification badge test', (WidgetTester tester) async {
    await tester.pumpWidget(const BharatDoorstepApp());

    // Navigate to Home page
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Enter 10-digit mobile number'),
      '9876543210',
    );
    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Verify & Continue'));
    await tester.pumpAndSettle();

    // Verify notification badge exists
    expect(find.text('3'), findsOneWidget);
    expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
  });

  testWidgets('Back navigation test', (WidgetTester tester) async {
    await tester.pumpWidget(const BharatDoorstepApp());

    // Navigate to Sign Up page
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    // Verify Sign Up page
    expect(find.text('Create Account'), findsOneWidget);

    // Tap back button
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    // Verify back to Landing page
    expect(find.text('Fast. Trusted. Doorstep Repairs.'), findsOneWidget);
  });

  testWidgets('City picker test', (WidgetTester tester) async {
    await tester.pumpWidget(const BharatDoorstepApp());

    // Navigate to Sign Up page
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    // Tap on city selector
    await tester.tap(find.text('Select your city'));
    await tester.pumpAndSettle();

    // Verify city options appear
    expect(find.text('Mumbai'), findsOneWidget);
    expect(find.text('Delhi'), findsOneWidget);
    expect(find.text('Bangalore'), findsOneWidget);
  });
}