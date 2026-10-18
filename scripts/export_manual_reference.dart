import 'dart:io';

void main() {
  final source = File(
    'lib/src/main/oculum_manual_sections.dart',
  ).readAsStringSync();
  final sections = RegExp(
    "titleIt: '((?:\\\\.|[^'])*)',[\\s\\S]*?contentIt: r?'''([\\s\\S]*?)'''",
    multiLine: true,
  ).allMatches(source).toList();
  final expected = RegExp(r'\bManualSection\(').allMatches(source).length;
  if (sections.length != expected || sections.isEmpty) {
    throw StateError(
      'Manual export incomplete: ${sections.length}/$expected sections',
    );
  }
  final document = StringBuffer('# Manuale Oculum — riferimento integrale\n\n');
  document.writeln(
    'Esportato dal manuale interno dell’app. Per le correzioni più recenti consultare prima [il registro delle regole confermate](OCULUM_REGOLE_CONFERMATE.md). Non modificare questa copia: aggiornare il sorgente e riesportare.\n',
  );
  for (final section in sections) {
    document.writeln('## ${section.group(1)!.replaceAll("\\'", "'")}\n');
    document.writeln('${section.group(2)!.trim()}\n');
  }
  File(
    'docs/manuale-consultazione.md',
  ).writeAsStringSync('${document.toString().trimRight()}\n');
  stdout.writeln('Exported ${sections.length} complete manual sections.');
}
