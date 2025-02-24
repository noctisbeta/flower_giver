import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:flower_giver/gemini_wrapper.dart';
import 'package:flower_giver/ipv6_client.dart';
import 'package:flower_giver/root_handler.dart';
import 'package:http/io_client.dart';
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
  if (!args.contains('--prod') && !args.contains('--dev')) {
    stderr.writeln('Error: Must specify either --prod or --dev flag');
    exit(1);
  }

  if (args.contains('--prod') && args.contains('--dev')) {
    stderr.writeln('Error: Cannot specify both --prod and --dev flags');
    exit(1);
  }

  final env = DotEnv()..load();
  final isProd = args.contains('--prod');

  geminiWrapper = GeminiWrapper(
    apiKey: env['GEMINI_API_KEY']!,
    httpClient:
        isProd
            ? IOClient(
              IPv6Client(targetHost: 'generativelanguage.googleapis.com'),
            )
            : null,
  );

  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addHandler(_router.call);

  final ip = isProd ? InternetAddress.anyIPv6 : InternetAddress.loopbackIPv4;
  final port = int.parse(
    Platform.environment['PORT'] ?? (isProd ? '8443' : '8080'),
  );

  final server = await (isProd ? _serveProduction : _serveDevelopment)(
    handler,
    ip,
    port,
  );

  print(
    'Server listening on ${server.address.address}:${server.port} (${isProd ? 'production' : 'development'} mode)',
  );
}

Future<HttpServer> _serveProduction(
  Handler handler,
  InternetAddress ip,
  int port,
) async {
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

  return serve(
    handler,
    ip,
    port,
    securityContext: securityContext,
    shared: false,
    poweredByHeader: null,
  );
}

Future<HttpServer> _serveDevelopment(
  Handler handler,
  InternetAddress ip,
  int port,
) async {
  return serve(handler, ip, port, shared: false, poweredByHeader: null);
}
