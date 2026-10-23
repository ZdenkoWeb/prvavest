import 'package:flutter_test/flutter_test.dart';
import 'package:prvavest/models.dart';

void main() {
  test('HTML znakovi u naslovu se pretvaraju u prave znakove', () {
    expect(decodeHtml('Rijera &#8211; &#8222;Zvezda&#8220; &amp; Kopenhagen'),
        'Rijera – „Zvezda“ & Kopenhagen');
  });
}
