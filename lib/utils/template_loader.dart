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
      if (key == 'message' && variables.containsKey('name')) {
        final name = variables['name']!;
        // Wrap name occurrences with highlight span
        value = value.replaceAll(
          RegExp(name, caseSensitive: false),
          '<span class="highlight">$name</span>',
        );
      }
      result = result.replaceAll('{{$key}}', value);
    });
    return result;
  }
}
