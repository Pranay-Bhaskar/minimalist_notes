class Note {
  String id;
  String title;
  String content;
  int createdAt;
  int updatedAt;

  Note({
    required this.id,
    this.title = '',
    this.content = '',
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  factory Note.fromJson(Map<String, dynamic> json) => Note(
        id: json['id'],
        title: json['title'],
        content: json['content'],
        createdAt: json['createdAt'],
        updatedAt: json['updatedAt'],
      );
}