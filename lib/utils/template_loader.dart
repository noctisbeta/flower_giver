import 'dart:io';

class TemplateLoader {
  final Map<String, String> _cache = {};
  final String _templateDir;

  TemplateLoader({String templateDir = 'lib/templates'})
    : _templateDir = templateDir;

  Future<String> load(String templateName) async {
    return _cache[templateName] ??= await _loadFile(templateName);
  }

  Future<String> _loadFile(String templateName) async {
    final file = File('$_templateDir/$templateName.html');
    return await file.readAsString();
  }

  String render(String template, Map<String, String> variables) {
    var result = template;
    variables.forEach((key, value) {
      if (key == 'message') {
        // Replace name tokens with highlight spans
        value = value.replaceAllMapped(
          RegExp(r'\[NAME\](.*?)\[/NAME\]'),
          (match) => '<span class="highlight">${match[1]}</span>',
        );
      }
      result = result.replaceAll('{{$key}}', value);
    });
    return result;
  }
}
