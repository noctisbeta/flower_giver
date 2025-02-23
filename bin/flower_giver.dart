import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:flower_giver/gemini_wrapper.dart';
import 'package:flower_giver/root_handler.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

// Global instance of GeminiWrapper
late final GeminiWrapper geminiWrapper;

// Configure routes.
final _router = Router()..get('/', _rootHandler);

Future<Response> _rootHandler(Request request) async {
  return await rootHandler(request, geminiWrapper);
}

void main(List<String> args) async {
  final env = DotEnv()..load();

  // Initialize the global instance early
  geminiWrapper = GeminiWrapper(apiKey: env['GEMINI_API_KEY']!);

  // Use IPv6 only
  final ip = InternetAddress.anyIPv6;
  print('Using IPv6 address: ${ip.address}');

  // Configure a pipeline that logs requests.
  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addHandler(_router.call);

  final certificateChain =
      '/etc/letsencrypt/live/flowers.fractalfable.com/fullchain.pem';
  final privateKey =
      '/etc/letsencrypt/live/flowers.fractalfable.com/privkey.pem';

  final certificate = File(certificateChain);
  final privateKeyFile = File(privateKey);

  final securityContext =
      SecurityContext()
        ..useCertificateChain(certificate.path)
        ..usePrivateKey(privateKeyFile.path);

  // For running in containers, we respect the PORT environment variable.
  final port = int.parse(Platform.environment['PORT'] ?? '8443');

  final server = await serve(
    handler,
    ip,
    port,
    securityContext: securityContext,
    shared: false,
    poweredByHeader: null,
  );

  print('Server listening on IPv6 ${server.address.address}:${server.port}');
}
