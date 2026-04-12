import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';

import 'package:tdp_frontend/core/providers.dart';
import 'package:tdp_frontend/models/user.dart';
import 'package:tdp_frontend/services/storage_service.dart';
import 'package:tdp_frontend/shared/api_url.dart';

/// Provider for the [WebSocketService].
final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  return WebSocketService(ref);
});

/// A service that handles realtime WebSocket communication using STOMP.
class WebSocketService {
  final Ref _ref;
  StompClient? _client;

  WebSocketService(this._ref);

  /// Initializes and connects the WebSocket client.
  Future<void> connect() async {
    final storage = _ref.read(storageServiceProvider);
    final token = await storage.getToken();
    final userId = await storage.getUserId();
    final role = await storage.getRole();
    final institutionId = await storage.getInstitutionId();

    if (token == null || userId == null) {
      debugPrint('WebSocket: Token or UserId is missing, cannot connect.');
      return;
    }

    debugPrint('WebSocket: Connecting to ${ApiUrl.wsUrl}...');

    _client = StompClient(
      config: StompConfig(
        url: ApiUrl.wsUrl,
        onConnect: (frame) => _onConnect(frame, userId, role, institutionId),
        onWebSocketError: (error) => debugPrint('WebSocket Error: $error'),
        stompConnectHeaders: {'Authorization': 'Bearer $token'},
        webSocketConnectHeaders: {'Authorization': 'Bearer $token'},
        onDisconnect: (frame) => debugPrint('WebSocket Disconnected'),
        onStompError: (frame) => debugPrint('WebSocket STOMP Error: ${frame.body}'),
      ),
    );

    _client?.activate();
  }

  void _onConnect(
    StompFrame frame,
    String userId,
    String? role,
    String? institutionId,
  ) {
    debugPrint('WebSocket: CONNECTED to server!');

    // 1. Subscribe to personal task updates
    _client?.subscribe(
      destination: '/topic/users/$userId/tasks',
      callback: (frame) {
        debugPrint('WebSocket: Personal Task Update received');
        _handleTaskEvent(frame.body);
      },
    );

    // 2. Subscribe to institution-wide task events
    if (institutionId != null) {
      debugPrint('WebSocket: Subscribing to institution $institutionId tasks');
      _client?.subscribe(
        destination: '/topic/institutions/$institutionId/tasks',
        callback: (frame) {
          debugPrint('WebSocket: Institution Task Event received');
          _handleTaskEvent(frame.body);
        },
      );
    } else {
      debugPrint('WebSocket: Skipping institution subscription (ID missing)');
    }
  }

  void _handleTaskEvent(String? body) {
    if (body == null) return;
    try {
      final data = jsonDecode(body);
      
      // Backend uses 'eventType' field name in TaskRealtimeEvent class
      final eventType = data['eventType']; 
      debugPrint('WebSocket Event Parsing: Event Type = $eventType');

      // Refresh relevant providers to trigger UI updates
      debugPrint('WebSocket: Invalidating providers for refreshing UI...');
      _ref.invalidate(pendingTasksProvider);
      _ref.invalidate(myTasksProvider);
      _ref.invalidate(dashboardStatsProvider);
      
      // Also potentially invalidate profile if name/points changed
      // _ref.invalidate(currentUserProvider);
    } catch (e) {
      debugPrint('WebSocket: Error parsing task event: $e');
    }
  }

  /// Disconnects the WebSocket client.
  void disconnect() {
    debugPrint('WebSocket: Deactivating client...');
    _client?.deactivate();
    _client = null;
  }
}
