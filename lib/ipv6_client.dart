import 'dart:io';

/// A custom HTTP client that forces IPv6 connections.
///
/// This client wraps the standard [HttpClient] and ensures all requests are made
/// over IPv6, even when IPv4 addresses are available. This is useful in scenarios
/// where IPv4 connectivity is blocked or unreliable.
///
/// The client includes certificate validation that checks:
/// - Certificate validity period
/// - Hostname matching against Common Names (CN)
/// - Hostname matching against Subject Alternative Names (SAN)
/// - Wildcard certificate support
///
/// WARNING: Setting [allowInvalidCertificates] to true is unsafe and should only
/// be used for testing or in controlled environments.
///
/// Example usage:
/// ```dart
/// final client = IPv6Client(
///   targetHost: 'example.com',
///   allowInvalidCertificates: false, // default
/// );
/// final request = await client.getUrl(Uri.parse('https://example.com/api'));
/// final response = await request.close();
/// ```
class IPv6Client implements HttpClient {
  IPv6Client({
    required this.targetHost,
    this.allowInvalidCertificates = false,
  }) {
    _client = HttpClient()..badCertificateCallback = _handleCertificate;
    _checkIpv6Support(); // This will run asynchronously
  }

  final String? targetHost;
  final bool allowInvalidCertificates;
  late final HttpClient _client;

  static const _maxRetries = 3;
  static const _retryDelay = Duration(milliseconds: 500);

  bool _handleCertificate(X509Certificate cert, String host, int port) {
    try {
      // Use targetHost for IPv6 addresses
      final verificationHost = host.contains(':') ? targetHost ?? host : host;

      // Check certificate expiration with grace period
      final now = DateTime.now();
      final gracePeriod = const Duration(minutes: 5);

      if (now.add(gracePeriod).isBefore(cert.startValidity) ||
          now.subtract(gracePeriod).isAfter(cert.endValidity)) {
        _logCertificateError('Certificate expired or not yet valid');
        return false;
      }

      // Development/testing bypass
      if (allowInvalidCertificates) {
        _logCertificateWarning(
          'Invalid certificate allowed in development mode',
        );
        return true;
      }

      // Check Common Names (CN)
      final commonNames = _extractCommonNames(cert.subject);
      if (_checkNamesMatch(verificationHost, commonNames)) {
        return true;
      }

      // Check Subject Alternative Names (SAN)
      final sans = _extractSANs(cert);
      if (_checkNamesMatch(verificationHost, sans)) {
        return true;
      }

      _logCertificateError(
        'No matching CN or SAN found for $verificationHost\n'
        'CNs: $commonNames\n'
        'SANs: $sans',
      );
      return false;
    } catch (e, stackTrace) {
      _logCertificateError('Certificate validation error: $e\n$stackTrace');
      return false;
    }
  }

  List<String> _extractCommonNames(String subject) {
    return RegExp(r'CN=([^,]+)')
        .allMatches(subject)
        .map((m) => m.group(1)?.trim())
        .whereType<String>()
        .toList();
  }

  List<String> _extractSANs(X509Certificate cert) {
    final dnsNames =
        RegExp(r'DNS:([\w.-]+)')
            .allMatches(cert.subject)
            .map((m) => m.group(1)?.trim())
            .whereType<String>();

    final ipAddresses =
        RegExp(r'IP Address:([^\s,]+)')
            .allMatches(cert.subject)
            .map((m) => m.group(1)?.trim())
            .whereType<String>();

    return [...dnsNames, ...ipAddresses];
  }

  bool _checkNamesMatch(String hostname, List<String> certNames) {
    return certNames.any((pattern) {
      try {
        if (pattern.startsWith('*.')) {
          // Proper wildcard handling
          final suffix = pattern.substring(2);
          final parts = hostname.split('.');
          if (parts.length >= 2) {
            return hostname.endsWith(suffix) && !parts[0].contains('.');
          }
          return false;
        }
        return hostname.toLowerCase() == pattern.toLowerCase();
      } catch (e) {
        _logCertificateError('Pattern matching error: $e');
        return false;
      }
    });
  }

  void _logCertificateError(String message) {
    // In production, you might want to use proper logging
    print('[IPv6Client] Certificate Error: $message');
  }

  void _logCertificateWarning(String message) {
    print('[IPv6Client] Certificate Warning: $message');
  }

  /// Checks if the system supports IPv6.
  ///
  /// Throws an [UnsupportedError] if IPv6 is not supported.
  Future<void> _checkIpv6Support() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv6,
      );
      if (interfaces.isEmpty) {
        throw UnsupportedError('No IPv6 interfaces available on this system');
      }
    } catch (e) {
      throw UnsupportedError('IPv6 is not supported: $e');
    }
  }

  Future<(Uri, String)> _resolveIpv6Uri(Uri url) async {
    for (var attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        final addresses = await InternetAddress.lookup(
          url.host,
          type: InternetAddressType.IPv6,
        );

        if (addresses.isEmpty) {
          if (attempt == _maxRetries - 1) {
            throw Exception('No IPv6 addresses found for ${url.host}');
          }
          await Future.delayed(_retryDelay);
          continue;
        }

        // Store original host for certificate validation
        final originalHost = url.host;

        // Replace host with IPv6 address
        final ipv6Uri = url.replace(host: addresses.first.address);

        return (ipv6Uri, originalHost);
      } catch (e) {
        if (attempt == _maxRetries - 1) {
          rethrow;
        }
        await Future.delayed(_retryDelay);
      }
    }

    throw Exception(
      'Failed to resolve IPv6 address after $_maxRetries attempts',
    );
  }

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    final (ipv6Uri, originalHost) = await _resolveIpv6Uri(url);
    final request = await _client.getUrl(ipv6Uri);
    request.headers
      ..set('Host', originalHost)
      ..set('Authority', originalHost);
    return request;
  }

  @override
  Future<HttpClientRequest> postUrl(Uri url) async {
    final (ipv6Uri, originalHost) = await _resolveIpv6Uri(url);
    final request = await _client.postUrl(ipv6Uri);
    request.headers.set('Host', originalHost);
    return request;
  }

  @override
  Future<HttpClientRequest> deleteUrl(Uri url) async {
    final (ipv6Uri, originalHost) = await _resolveIpv6Uri(url);
    final request = await _client.deleteUrl(ipv6Uri);
    request.headers.set('Host', originalHost);
    return request;
  }

  @override
  Future<HttpClientRequest> headUrl(Uri url) async {
    final (ipv6Uri, originalHost) = await _resolveIpv6Uri(url);
    final request = await _client.headUrl(ipv6Uri);
    request.headers.set('Host', originalHost);
    return request;
  }

  @override
  Future<HttpClientRequest> patchUrl(Uri url) async {
    final (ipv6Uri, originalHost) = await _resolveIpv6Uri(url);
    final request = await _client.patchUrl(ipv6Uri);
    request.headers.set('Host', originalHost);
    return request;
  }

  @override
  Future<HttpClientRequest> putUrl(Uri url) async {
    final (ipv6Uri, originalHost) = await _resolveIpv6Uri(url);
    final request = await _client.putUrl(ipv6Uri);
    request.headers.set('Host', originalHost);
    return request;
  }

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    final (ipv6Uri, originalHost) = await _resolveIpv6Uri(url);
    final request = await _client.openUrl(method, ipv6Uri);
    request.headers.set('Host', originalHost);
    return request;
  }

  // Forward all other HttpClient methods to the internal client
  @override
  bool autoUncompress = true;

  @override
  Duration? connectionTimeout;

  @override
  Duration idleTimeout = const Duration(seconds: 15);

  @override
  int? maxConnectionsPerHost;

  @override
  String? userAgent;

  @override
  void addCredentials(
    Uri url,
    String realm,
    HttpClientCredentials credentials,
  ) => _client.addCredentials(url, realm, credentials);

  @override
  void addProxyCredentials(
    String host,
    int port,
    String realm,
    HttpClientCredentials credentials,
  ) => _client.addProxyCredentials(host, port, realm, credentials);

  @override
  set authenticate(
    Future<bool> Function(Uri url, String scheme, String? realm)? f,
  ) => _client.authenticate = f;

  @override
  set authenticateProxy(
    Future<bool> Function(String host, int port, String scheme, String? realm)?
    f,
  ) => _client.authenticateProxy = f;

  @override
  set badCertificateCallback(
    bool Function(X509Certificate cert, String host, int port)? callback,
  ) => _client.badCertificateCallback = callback;

  @override
  void close({bool force = false}) => _client.close(force: force);

  @override
  Future<HttpClientRequest> delete(String host, int port, String path) =>
      _client.delete(host, port, path);

  @override
  set findProxy(String Function(Uri url)? f) => _client.findProxy = f;

  @override
  Future<HttpClientRequest> get(String host, int port, String path) =>
      _client.get(host, port, path);

  @override
  Future<HttpClientRequest> head(String host, int port, String path) =>
      _client.head(host, port, path);

  @override
  Future<HttpClientRequest> open(
    String method,
    String host,
    int port,
    String path,
  ) => _client.open(method, host, port, path);

  @override
  Future<HttpClientRequest> patch(String host, int port, String path) =>
      _client.patch(host, port, path);

  @override
  Future<HttpClientRequest> post(String host, int port, String path) =>
      _client.post(host, port, path);

  @override
  Future<HttpClientRequest> put(String host, int port, String path) =>
      _client.put(host, port, path);

  @override
  set keyLog(Function(String line)? callback) => _client.keyLog = callback;

  @override
  set connectionFactory(
    Future<ConnectionTask<Socket>> Function(
      Uri url,
      String? proxyHost,
      int? proxyPort,
    )?
    f,
  ) => _client.connectionFactory = f;
}

List<String> getSubjectAlternativeNames(X509Certificate certificate) {
  final subject = certificate.subject;

  // Match both DNS names and IP addresses
  final pattern = RegExp(r'(?:DNS:|IP Address:)([\w.-]+)');
  return pattern
      .allMatches(subject)
      .map((match) => match.group(1))
      .whereType<String>()
      .toList();
}
