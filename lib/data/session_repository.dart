import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'nada_models.dart';

/// The only contract the app has with its storage.
///
/// Swapping this for a Supabase-backed implementation is the entire premium
/// migration. The UI and domain code do not know where the ledger lives.
abstract interface class SessionRepository {
  Future<NadaStoreData> load();
  Future<void> save(NadaStoreData data);
}

/// Local-first, zero-account, zero-network. A single JSON document in the
/// application support directory. Writes happen only on state changes
/// (start, pause, resume, finish), never on the ticking second.
class LocalSessionRepository implements SessionRepository {
  LocalSessionRepository({this.fileName = 'nada.json'});

  final String fileName;
  File? _cachedFile;

  Future<File> _file() async {
    final cached = _cachedFile;
    if (cached != null) return cached;
    final directory = await getApplicationSupportDirectory();
    return _cachedFile = File(
      '${directory.path}${Platform.pathSeparator}$fileName',
    );
  }

  @override
  Future<NadaStoreData> load() async {
    try {
      final file = await _file();
      if (!await file.exists()) return const NadaStoreData();
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) return const NadaStoreData();
      return NadaStoreData.fromJson(jsonDecode(raw) as Map<String, Object?>);
    } catch (_) {
      // A corrupt ledger should never cost you the app. Start clean.
      return const NadaStoreData();
    }
  }

  @override
  Future<void> save(NadaStoreData data) async {
    final file = await _file();
    await file.parent.create(recursive: true);
    final payload = jsonEncode(data.toJson());

    // Write beside the real file first, then swap. If the process dies
    // mid-write, the previous ledger stays intact.
    final temp = File('${file.path}.tmp');
    await temp.writeAsString(payload, flush: true);
    try {
      await temp.rename(file.path);
    } on FileSystemException {
      // Windows cannot rename over an existing file; Android can.
      if (await file.exists()) await file.delete();
      await temp.rename(file.path);
    }
  }
}
