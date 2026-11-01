/// Bola bilan qilingan ish turi
enum WorkKind {
  assessment('Baholash'),
  session('Mashg‘ulot'),
  observation('Kuzatuv'),
  measurement('O‘lchov'),
  subjectLevel('Bilim darajasi'),
  subjectTask('Fan topshirig‘i'),
  conference('Konsilium xulosasi');

  final String label;
  const WorkKind(this.label);
}

/// Bola bilan qilingan ish haqida qisqa yozuv: kim, qachon, qanday ish.
/// Mazmun (izoh, natija matni) yo'q — monitoring maxfiy ma'lumotni ochmasdan ishlaydi.
class WorkRecord {
  final String userId;
  final DateTime at;
  final WorkKind kind;

  const WorkRecord(this.userId, this.at, this.kind);
}
