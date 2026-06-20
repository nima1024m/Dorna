/// A library phrase (mapped to the backend `/v1/phrases` response).
class Phrase {
  final int id;
  final String text;
  final String? ipa;
  final String? translation; // Persian gloss
  final String? whenToUse;
  final String? example;
  final String? category;
  final bool saved;

  const Phrase({
    required this.id,
    required this.text,
    this.ipa,
    this.translation,
    this.whenToUse,
    this.example,
    this.category,
    this.saved = false,
  });

  factory Phrase.fromJson(Map<String, dynamic> json) => Phrase(
        id: json['id'] as int,
        text: json['text']?.toString() ?? '',
        ipa: json['ipa']?.toString(),
        translation: json['translation']?.toString(),
        whenToUse: json['when_to_use']?.toString(),
        example: json['example']?.toString(),
        category: json['category']?.toString(),
        saved: json['saved'] == true,
      );

  Phrase copyWith({bool? saved}) => Phrase(
        id: id,
        text: text,
        ipa: ipa,
        translation: translation,
        whenToUse: whenToUse,
        example: example,
        category: category,
        saved: saved ?? this.saved,
      );
}
