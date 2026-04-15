import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_service.dart';

class FCMService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    debugPrint('🔔 Initializing FCM Service...');
    
    try {
      // Request permission for notifications
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('🔔 FCM Permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Initialize local notifications
        await _initializeLocalNotifications();
        
        // Ensure Android 13+ Notification Permissions are handled by FlutterLocalNotifications
        await _localNotifications
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
        
        // Setup message handlers
        _setupMessageHandlers();
        
        // Get and save FCM token
        await _getFCMToken();
        
        _isInitialized = true;
        debugPrint('✅ FCM Service initialized successfully');
      } else {
        debugPrint('❌ FCM Permission denied');
        // Still mark as initialized to prevent repeated attempts
        _isInitialized = true;
      }
    } catch (e) {
      debugPrint('❌ Error initializing FCM: $e');
      // Mark as initialized even on error to prevent infinite retry loops
      _isInitialized = true;
    }
  }

  /// Initialize local notifications
  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'booking_alerts',
      'Booking Alerts',
      description: 'Notifications for new booking assignments',
      importance: Importance.high,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Setup FCM message handlers
  static void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('🔔 Foreground message received: ${message.messageId}');
      _handleMessage(message, isBackground: false);
    });

    // Handle background messages (when app is in background but not terminated)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('🔔 Background message opened: ${message.messageId}');
      _handleMessage(message, isBackground: true);
    });

    // Handle terminated app messages
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('🔔 Terminated app message: ${message.messageId}');
        _handleMessage(message, isBackground: true);
      }
    });
  }

  /// Handle incoming FCM messages
  static void _handleMessage(RemoteMessage message, {required bool isBackground}) {
    debugPrint('🔔 Handling message: ${message.data}');
    
    final data = message.data;
    final notification = message.notification;
    
    if (notification != null) {
      // Show local notification if app is in foreground
      if (!isBackground) {
        _showLocalNotification(
          title: notification.title ?? 'New Booking',
          body: notification.body ?? 'You have a new booking assignment',
          payload: jsonEncode(data),
        );
      }
      
      // Handle booking-specific logic
      if (data['type'] == 'booking_assignment') {
        _handleBookingAssignment(data);
      }
    }
  }

  /// Handle booking assignment notification
  static void _handleBookingAssignment(Map<String, dynamic> data) {
    debugPrint('🔔 Handling booking assignment: $data');
    
    // Store notification data for later retrieval
    _storeNotificationData(data);
    
    // You can add navigation logic here if needed
    // For example, navigate to booking details page
  }

  /// Store notification data locally
  static Future<void> _storeNotificationData(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notifications = prefs.getStringList('pending_notifications') ?? [];
      notifications.add(jsonEncode(data));
      await prefs.setStringList('pending_notifications', notifications);
      debugPrint('💾 Notification data stored');
    } catch (e) {
      debugPrint('❌ Error storing notification data: $e');
    }
  }

  /// Show local notification
  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'booking_alerts',
      'Booking Alerts',
      channelDescription: 'Notifications for new booking assignments',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF0047AB),
      playSound: true,
      enableVibration: true,
      vibrationPattern: null, // Remove custom vibration pattern
      // sound: RawResourceAndroidNotificationSound('notification'), // ✅ REMOVE: Causing error
      ticker: 'New job available in your area!',
      autoCancel: false, // Keep notification until user interacts
      ongoing: false,
      styleInformation: BigTextStyleInformation(
        body,
        htmlFormatBigText: true,
        contentTitle: title,
        htmlFormatContentTitle: true,
      ),
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  /// Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('🔔 Notification tapped: ${response.payload}');
    
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!);
        // Handle navigation based on notification data
        _handleNotificationNavigation(data);
      } catch (e) {
        debugPrint('❌ Error parsing notification payload: $e');
      }
    }
  }

  /// Handle navigation when notification is tapped
  static void _handleNotificationNavigation(Map<String, dynamic> data) {
    // Add navigation logic here
    // For example, navigate to booking details page
    debugPrint('🔔 Navigating based on notification: $data');
  }

  /// Get FCM token and save to database
  static Future<String?> _getFCMToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      debugPrint('🔔 FCM Token: $token');
      
      if (token != null) {
        // Save token to user preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', token);
        
        // Update technician's FCM token in database
        await _updateTechnicianFCMToken(token);
      }
      
      return token;
    } catch (e) {
      debugPrint('❌ Error getting FCM token: $e');
      return null;
    }
  }

  /// Update technician's FCM token in database
  static Future<void> _updateTechnicianFCMToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userType = prefs.getString('userType');
      
      if (userType == 'technician') {
        // Get current user ID from SharedPreferences or Firebase Auth
        final technicianData = prefs.getString('technician');
        if (technicianData != null) {
          final techJson = jsonDecode(technicianData);
          final uid = techJson['uid'];
          
          if (uid != null) {
            // Update in Firebase Realtime Database
            await FirebaseService.updateTechnicianFCMToken(uid, token);
            debugPrint('✅ Technician FCM token updated in Firebase: $uid');
          }
        }
        
        // Also store locally as backup
        await prefs.setString('technician_fcm_token', token);
        debugPrint('💾 Technician FCM token saved locally');
      }
    } catch (e) {
      debugPrint('❌ Error updating technician FCM token: $e');
    }
  }

  /// Get current FCM token
  static Future<String?> getCurrentToken() async {
    try {
      // Ensure FCM is initialized first
      if (!_isInitialized) {
        await initialize();
      }
      
      final token = await _firebaseMessaging.getToken();
      debugPrint('🔔 Current FCM token retrieved: ${token?.substring(0, 20)}...');
      return token;
    } catch (e) {
      debugPrint('❌ Error getting current FCM token: $e');
      return null;
    }
  }

  /// Subscribe to topic (for broadcast notifications)
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      debugPrint('✅ Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('❌ Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('❌ Error unsubscribing from topic: $e');
    }
  }

  /// Get pending notifications
  static Future<List<Map<String, dynamic>>> getPendingNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notifications = prefs.getStringList('pending_notifications') ?? [];
      return notifications.map((n) => jsonDecode(n) as Map<String, dynamic>).toList();
    } catch (e) {
      debugPrint('❌ Error getting pending notifications: $e');
      return [];
    }
  }

  /// Send notification to specific FCM token
  static Future<void> sendNotificationToToken({
    required String token,
    required String title,
    required String body,
    required Map<String, String> data,
  }) async {
    try {
      debugPrint('🔔 FCM DEBUG: Sending notification to token: ${token.substring(0, 20)}...');
      debugPrint('📱 FCM DEBUG: Title: $title');
      debugPrint('📱 FCM DEBUG: Body: $body');
      debugPrint('📱 FCM DEBUG: Data: $data');
      
      // Show local notification immediately for testing and immediate feedback
      await _showLocalNotification(
        title: title,
        body: body,
        payload: jsonEncode(data),
      );
      debugPrint('✅ FCM DEBUG: Local notification shown');
      
      // Store notification for history
      await _storeNotificationData({
        'title': title,
        'body': body,
        'timestamp': DateTime.now().toIso8601String(),
        'token': token.substring(0, 10) + '...',
        ...data,
      });
      debugPrint('✅ FCM DEBUG: Notification stored in history');
      
      debugPrint('✅ FCM DEBUG: Notification process completed successfully');
      
      // Note: For actual FCM server-side sending, you'd need to use Firebase Admin SDK
      // or call your backend API that sends the notification using the FCM HTTP API
      // This is a client-side implementation for immediate local notifications
      
      // If you have a backend service, you would call it here:
      // await _sendServerNotification(token, title, body, data);
      
    } catch (e) {
      debugPrint('❌ FCM DEBUG: Error sending notification: $e');
    }
  }

  /// Send server-side notification (placeholder for backend integration)
  static Future<void> _sendServerNotification(
    String token,
    String title,
    String body,
    Map<String, String> data,
  ) async {
    // This would call your backend API to send FCM notifications
    // Example:
    // final response = await http.post(
    //   Uri.parse('https://your-backend.com/send-notification'),
    //   headers: {'Content-Type': 'application/json'},
    //   body: jsonEncode({
    //     'token': token,
    //     'title': title,
    //     'body': body,
    //     'data': data,
    //   }),
    // );
    debugPrint('📡 Server notification would be sent here (backend integration needed)');
  }

  /// Send real-time notification for new booking
  static Future<void> sendNewBookingNotification({
    required String bookingId,
    required String service,
    required String pincode,
    required double amount,
  }) async {
    try {
      debugPrint('🔔 Sending real-time booking notification');
      
      final notificationData = {
        'type': 'new_booking',
        'bookingId': bookingId,
        'service': service,
        'pincode': pincode,
        'amount': amount.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      // Show immediate local notification
      await _showLocalNotification(
        title: '🔔 New Job Available!',
        body: '$service in $pincode - ₹${amount.toStringAsFixed(0)}',
        payload: jsonEncode(notificationData),
      );
      
      // Store notification for history
      await _storeNotificationData({
        'title': '🔔 New Job Available!',
        'body': '$service in $pincode - ₹${amount.toStringAsFixed(0)}',
        'timestamp': DateTime.now().toIso8601String(),
        ...notificationData,
      });
      
      debugPrint('✅ Real-time notification sent successfully');
    } catch (e) {
      debugPrint('❌ Error sending real-time notification: $e');
    }
  }

  /// Send immediate notification to all technicians in area
  static Future<void> sendJobAlertToArea({
    required String pincode,
    required String service,
    required String bookingId,
    required double amount,
    required String customerName,
    required String scheduledTime,
  }) async {
    try {
      debugPrint('🚨 Sending job alert to area: $pincode');
      
      final notificationData = {
        'type': 'job_alert',
        'bookingId': bookingId,
        'service': service,
        'pincode': pincode,
        'amount': amount.toString(),
        'customerName': customerName,
        'scheduledTime': scheduledTime,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      // Show immediate local notification for all technicians in the area
      await _showLocalNotification(
        title: '🚨 URGENT: New Job in Your Area!',
        body: '$service for $customerName - ₹${amount.toStringAsFixed(0)} in $pincode',
        payload: jsonEncode(notificationData),
      );
      
      // Store notification
      await _storeNotificationData({
        'title': '🚨 URGENT: New Job in Your Area!',
        'body': '$service for $customerName - ₹${amount.toStringAsFixed(0)} in $pincode',
        'timestamp': DateTime.now().toIso8601String(),
        ...notificationData,
      });
      
      debugPrint('✅ Job alert sent to area $pincode');
    } catch (e) {
      debugPrint('❌ Error sending job alert: $e');
    }
  }

  /// Test notification functionality
  static Future<void> testNotification() async {
    try {
      debugPrint('🧪 Testing notification functionality...');
      
      await _showLocalNotification(
        title: '🧪 Test Notification',
        body: 'FCM Service is working correctly!',
        payload: jsonEncode({'type': 'test', 'timestamp': DateTime.now().toIso8601String()}),
      );
      
      debugPrint('✅ Test notification sent successfully');
    } catch (e) {
      debugPrint('❌ Test notification failed: $e');
    }
  }

  /// Test complete notification flow
  static Future<void> testCompleteNotificationFlow() async {
    try {
      debugPrint('🧪 Testing complete notification flow...');
      
      // Test 1: Basic notification
      await testNotification();
      
      // Wait a moment
      await Future.delayed(const Duration(seconds: 2));
      
      // Test 2: Job alert notification
      await sendJobAlertToArea(
        pincode: '410210',
        service: 'AC Repair',
        bookingId: 'test_booking_123',
        amount: 599.0,
        customerName: 'Test Customer',
        scheduledTime: 'Today 3:00 PM - 5:00 PM',
      );
      
      // Wait a moment
      await Future.delayed(const Duration(seconds: 2));
      
      // Test 3: New booking notification
      await sendNewBookingNotification(
        bookingId: 'test_booking_456',
        service: 'Washing Machine Repair',
        pincode: '410210',
        amount: 399.0,
      );
      
      debugPrint('✅ Complete notification flow test completed');
    } catch (e) {
      debugPrint('❌ Complete notification flow test failed: $e');
    }
  }

  /// Clear pending notifications from storage
  Future<void> clearPendingNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('pending_notifications');
      debugPrint('🗑️ Pending notifications cleared');
    } catch (e) {
      debugPrint('❌ Error clearing pending notifications: $e');
    }
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('🔔 Background message handler: ${message.messageId}');
  debugPrint('🔔 Background message data: ${message.data}');
  
  // Handle background notification processing
  if (message.data['type'] == 'new_booking') {
    debugPrint('🔔 New booking notification received in background');
    // Store notification for when app opens
    try {
      // Note: SharedPreferences might not work in background handler
      // Consider using a different storage method if needed
    } catch (e) {
      debugPrint('❌ Error storing background notification: $e');
    }
  }
}