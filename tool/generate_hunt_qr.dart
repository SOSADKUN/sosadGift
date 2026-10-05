import 'dart:io';
import 'package:qr/qr.dart';
import 'package:gift/config/treasure_hunt_config.dart';

void main() {
  final qr = QrImage(
    QrCode.fromData(
      data: TreasureHuntConfig.finalQrCode,
      errorCorrectLevel: QrErrorCorrectLevel.M,
    ),
  );
  final extent = qr.moduleCount + 8;
  final svg = StringBuffer(
    '<svg xmlns="http://www.w3.org/2000/svg" width="800" height="800" viewBox="0 0 $extent $extent"><rect width="$extent" height="$extent" fill="white"/>',
  );
  for (var row = 0; row < qr.moduleCount; row++) {
    for (var col = 0; col < qr.moduleCount; col++) {
      if (qr.isDark(row, col)) {
        svg.write(
          '<rect x="${col + 4}" y="${row + 4}" width="1" height="1" fill="black"/>',
        );
      }
    }
  }
  svg.write('</svg>');
  File('print/final_hunt_qr.svg').writeAsStringSync(svg.toString());
}
