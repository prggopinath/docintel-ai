import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';

class TextDocxExportService {
  Future<Uint8List> createDocx({
    required String text,
    required String title,
  }) async {
    final archive = Archive();

    final documentXml = _buildDocumentXml(
      text: text,
      title: title,
    );

    final contentTypesXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
</Types>''';

    final relationshipsXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship
    Id="rId1"
    Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument"
    Target="word/document.xml"/>
</Relationships>''';

    final documentRelationshipsXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
</Relationships>''';

    archive.addFile(
      ArchiveFile(
        '[Content_Types].xml',
        utf8.encode(contentTypesXml).length,
        utf8.encode(contentTypesXml),
      ),
    );

    archive.addFile(
      ArchiveFile(
        '_rels/.rels',
        utf8.encode(relationshipsXml).length,
        utf8.encode(relationshipsXml),
      ),
    );

    archive.addFile(
      ArchiveFile(
        'word/document.xml',
        utf8.encode(documentXml).length,
        utf8.encode(documentXml),
      ),
    );

    archive.addFile(
      ArchiveFile(
        'word/_rels/document.xml.rels',
        utf8.encode(documentRelationshipsXml).length,
        utf8.encode(documentRelationshipsXml),
      ),
    );

    final zipBytes = ZipEncoder().encode(archive);    

    return Uint8List.fromList(zipBytes);
  }

  String _buildDocumentXml({
    required String text,
    required String title,
  }) {
    final buffer = StringBuffer();

    buffer.write('''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document
  xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
''');

    buffer.write(_paragraph(
      title,
      bold: true,
      fontSize: 32,
    ));

    buffer.write(_paragraph(
      'Extracted Text',
      bold: true,
      fontSize: 22,
    ));

    for (final line in text.split('\n')) {
      buffer.write(_paragraph(line));
    }

    buffer.write('''
    <w:sectPr>
      <w:pgSz w:w="11906" w:h="16838"/>
      <w:pgMar
        w:top="1440"
        w:right="1440"
        w:bottom="1440"
        w:left="1440"/>
    </w:sectPr>
  </w:body>
</w:document>''');

    return buffer.toString();
  }

  String _paragraph(
    String text, {
    bool bold = false,
    int fontSize = 22,
  }) {
    final escapedText = _escapeXml(text);

    final runProperties = bold
        ? '''
          <w:rPr>
            <w:b/>
            <w:sz w:val="$fontSize"/>
          </w:rPr>
'''
        : '''
          <w:rPr>
            <w:sz w:val="$fontSize"/>
          </w:rPr>
''';

    return '''
    <w:p>
      <w:r>
        $runProperties
        <w:t xml:space="preserve">$escapedText</w:t>
      </w:r>
    </w:p>
''';
  }

  String _escapeXml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}