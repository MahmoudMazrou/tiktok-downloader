import 'dart:io';

class FFile {
  final FileSystemEntity file;
  final DateTime date;

  FFile({required this.file, required this.date});

  @override
  String toString() {
    return '{$file, $date}';
  }
}
