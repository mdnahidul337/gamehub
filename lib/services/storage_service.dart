import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'dart:typed_data';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  /// Uploads a local file to Firebase Storage under a generated path and returns the download URL.
  Future<String> uploadFile(File file, {String? folder}) async {
    final id = _uuid.v4();
    final fileName = file.path.split(Platform.pathSeparator).last;
    final path = '${folder ?? 'mods'}/$id/$fileName';
    final ref = _storage.ref().child(path);
    final task = await ref.putFile(file);
    return await task.ref.getDownloadURL();
  }

  /// Upload bytes with a generated name under folder.
  Future<String> uploadBytes(List<int> bytes, String extension,
      {String? folder}) async {
    final id = _uuid.v4();
    final path = '${folder ?? 'mods'}/$id/file.$extension';
    final ref = _storage.ref().child(path);
    final data = Uint8List.fromList(bytes);
    final task = await ref.putData(data);
    return await task.ref.getDownloadURL();
  }
}
