// Modèle de données d'un diplôme certifié sur blockchain
// Immutable, sérialisable JSON, avec validation intégrée

class Diploma {
  final String id;
  final String title;
  final String university;
  final DateTime date; // Changé de String à DateTime pour faciliter tri et formatage
  final String studentName;
  final String blockchainHash;
  final String? specialization; // Spécialisation optionnelle
  final String? mention; // Mention (Très Bien, Bien…)
  final bool isVerified;

  const Diploma({
    required this.id,
    required this.title,
    required this.university,
    required this.date,
    required this.studentName,
    required this.blockchainHash,
    this.specialization,
    this.mention,
    this.isVerified = true,
  });

  /// Désérialisation depuis JSON (API blockchain)
  factory Diploma.fromJson(Map<String, dynamic> json) {
    return Diploma(
      id: json['id'] as String,
      title: json['title'] as String,
      university: json['university'] as String,
      date: DateTime.parse(json['date'] as String),
      studentName: json['studentName'] as String,
      blockchainHash: json['blockchainHash'] as String,
      specialization: json['specialization'] as String?,
      mention: json['mention'] as String?,
      isVerified: json['isVerified'] as bool? ?? true,
    );
  }

  /// Sérialisation vers JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'university': university,
        'date': date.toIso8601String(),
        'studentName': studentName,
        'blockchainHash': blockchainHash,
        'specialization': specialization,
        'mention': mention,
        'isVerified': isVerified,
      };

  /// Chemin public de verification. L'URL absolue est construite par ApiConfig.
  String get verificationUrl =>
      '/api/public/diplomas/${Uri.encodeComponent(blockchainHash)}';

  /// Hash tronqué pour affichage (ex: 0x71b2...3a4f)
  String get shortHash {
    if (blockchainHash.length <= 10) return blockchainHash;
    return '${blockchainHash.substring(0, 6)}...${blockchainHash.substring(blockchainHash.length - 4)}';
  }

  @override
  String toString() => 'Diploma(id: $id, title: $title, student: $studentName)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Diploma &&
          other.id == id &&
          other.blockchainHash == blockchainHash;

  @override
  int get hashCode => id.hashCode ^ blockchainHash.hashCode;
}
