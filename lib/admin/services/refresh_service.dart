import 'package:flutter/material.dart';

class RefreshService {
  static final RefreshService _instance = RefreshService._internal();
  factory RefreshService() => _instance;
  RefreshService._internal();

  // List of callbacks to call when refresh is needed
  final List<VoidCallback> _refreshCallbacks = [];

  // Register a refresh callback
  void registerRefreshCallback(VoidCallback callback) {
    _refreshCallbacks.add(callback);
  }

  // Unregister a refresh callback
  void unregisterRefreshCallback(VoidCallback callback) {
    _refreshCallbacks.remove(callback);
  }

  // Trigger refresh on all registered callbacks
  void triggerRefresh() {
    for (final callback in _refreshCallbacks) {
      try {
        callback();
      } catch (e) {
        print('Error calling refresh callback: $e');
      }
    }
  }
}
