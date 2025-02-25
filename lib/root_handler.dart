import 'package:flower_giver/gemini_wrapper.dart';
import 'package:flower_giver/utils/template_loader.dart';
import 'package:shelf/shelf.dart';

Future<Response> rootHandler(
  Request request,
  GeminiWrapper geminiWrapper,
  TemplateLoader templateLoader,
) async {
  final String? name = request.url.queryParameters['name'];
  final String lang = request.url.queryParameters['lang'] ?? 'en';

  final baseTemplate = await templateLoader.load('base');
  final String content;
  if (name != null) {
    final geminiResponse = await geminiWrapper.customizedResponse(name, lang);
    final messageTemplate = await templateLoader.load('message');
    content = templateLoader.render(messageTemplate, {
      'message': geminiResponse,
      'name': name,
    });
  } else {
    content = await templateLoader.load('no_message');
  }

  final baseRender = templateLoader.render(baseTemplate, {'content': content});

  return Response.ok(baseRender, headers: {'content-type': 'text/html'});
}
