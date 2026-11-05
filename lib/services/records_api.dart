import 'api_client.dart';

/// Bitta o'zgarish: qo'shish/yangilash (`put`) yoki o'chirish (`delete`).
class RecordOp {
  final String op;
  final String kind;
  final String id;
  final Map<String, dynamic>? data;

  const RecordOp.put(this.kind, this.id, Map<String, dynamic> this.data)
    : op = 'put';
  const RecordOp.delete(this.kind, this.id) : op = 'delete', data = null;

  Map<String, dynamic> toJson() => {
    'op': op,
    'kind': kind,
    'id': id,
    if (data != null) 'data': data,
  };
}

/// Hamkasbning ismi va roli (email, telefon va profil kelmaydi).
class DirectoryEntry {
  final String id;
  final String fullName;
  final String role;
  final String? institutionId;

  const DirectoryEntry({
    required this.id,
    required this.fullName,
    required this.role,
    this.institutionId,
  });

  factory DirectoryEntry.fromJson(Map<String, dynamic> j) => DirectoryEntry(
    id: j['id'] as String,
    fullName: j['full_name'] as String? ?? '',
    role: j['role'] as String? ?? '',
    institutionId: j['institution_id'] as String?,
  );
}

/// Ish ma'lumotlari (bolalar va ular haqidagi barcha yozuvlar) serverda.
/// Server har bir foydalanuvchiga faqat ko'rishi mumkin bo'lganini beradi va
/// kim nimani o'zgartira olishini o'zi tekshiradi.
class RecordsApi {
  RecordsApi([ApiClient? client]) : _api = client ?? ApiClient.instance;

  final ApiClient _api;

  /// Bitta so'rovda yuboriladigan amallar soni (server chegarasi 500).
  static const batchLimit = 400;

  /// Foydalanuvchi ko'ra oladigan hamma narsa, tur bo'yicha.
  Future<Map<String, List<Map<String, dynamic>>>> load() async {
    final body = await _api.get('/api/records');
    final items = (body['items'] as Map?) ?? const {};
    return {
      for (final e in items.entries)
        e.key as String: [
          for (final row in (e.value as List? ?? const []))
            (row as Map).cast<String, dynamic>(),
        ],
    };
  }

  /// O'zgarishlarni yuboradi; har bir to'plam serverda yo hammasi saqlanadi,
  /// yo hech biri. Javob — server tuzatgan yakuniy ko'rinish (`kind`, `data`).
  Future<List<({String kind, Map<String, dynamic> data})>> apply(
    List<RecordOp> ops,
  ) async {
    final out = <({String kind, Map<String, dynamic> data})>[];
    for (var i = 0; i < ops.length; i += batchLimit) {
      final chunk = ops.sublist(
        i,
        i + batchLimit > ops.length ? ops.length : i + batchLimit,
      );
      final body = await _api.post('/api/records/batch', {
        'ops': [for (final o in chunk) o.toJson()],
      });
      for (final item in (body['items'] as List? ?? const [])) {
        final m = (item as Map).cast<String, dynamic>();
        out.add((
          kind: m['kind'] as String,
          data: (m['data'] as Map).cast<String, dynamic>(),
        ));
      }
    }
    return out;
  }

  Future<List<DirectoryEntry>> directory() async => [
    for (final e in await _api.getList('/api/directory'))
      DirectoryEntry.fromJson((e as Map).cast<String, dynamic>()),
  ];
}
