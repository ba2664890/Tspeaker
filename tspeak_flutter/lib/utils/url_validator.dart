import 'package:flutter/material.dart';

class UrlValidator {
  static String? baseUrl;

  static bool isValidUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https') && uri.hasAuthority;
    } catch (_) {
      return false;
    }
  }

  static String wrapUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (isValidUrl(url)) return url;
    if (url.startsWith('/') && baseUrl != null) {
      return '$baseUrl$url';
    }
    return url;
  }

  static ImageProvider getSafeImage(String? url, {String placeholder = 'assets/images/logo.png'}) {
    final wrapped = wrapUrl(url);
    if (isValidUrl(wrapped)) {
      return NetworkImage(wrapped);
    }
    return AssetImage(placeholder);
  }
}
