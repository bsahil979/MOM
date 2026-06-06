import 'file_saver_stub.dart'
    if (dart.library.html) 'file_saver_web.dart';

class FileSaver {
  /// Saves text content as a file on the user's platform (downloads directly in browser on Web).
  static void saveFile(String content, String filename) {
    saveFileImpl(content, filename);
  }
}
