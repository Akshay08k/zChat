import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart';

class NotificationService {
  static const String fcmUrl =
      'https://fcm.googleapis.com/v1/projects/thinksync-2dc60/messages:send';

  // Load service account JSON from assets
  static Future<ServiceAccountCredentials> _loadServiceAccount() async {
    final jsonString = await rootBundle.loadString('assets/keys.json');
    final jsonMap = json.decode(jsonString);
    return ServiceAccountCredentials.fromJson(jsonMap);
  }

  static Future<void> sendPushNotification({
    required String fcmToken,
    required String title,
    required String body,
  }) async {
    try {
      final account = await _loadServiceAccount();
      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

      final client = await clientViaServiceAccount(account, scopes);

      final message = {
        "message": {
          "token": fcmToken,
          "notification": {
            "title": title,
            "body": body,
          },
          "android": {
            "priority": "HIGH",
            "notification": {
              "channel_id": "chat_channel"
            }
          },
        }
      };

      final response = await client.post(
        Uri.parse(fcmUrl),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(message),
      );

      if (response.statusCode == 200) {
        print('Push notification sent!');
      } else {
        print('Error sending push notification: ${response.body}');
      }

      client.close();
    } catch (e) {
      print('Exception in sending push notification: $e');
    }
  }
}
