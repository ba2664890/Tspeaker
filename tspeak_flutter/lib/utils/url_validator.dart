import 'package:flutter/material.dart';

class UrlValidator {
  static bool isValidUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https') && uri.hasAuthority;
    } catch (_) {
      return false;
    }
  }

  static ImageProvider getSafeImage(String? url, {String placeholder = 'assets/images/logo.png'}) {
    if (isValidUrl(url)) {
      return NetworkImage(url!);
    }
    return AssetImage(placeholder);
  }
}
