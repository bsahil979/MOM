import 'dart:convert';

class ActionItem {
  String description;
  String assignee;
  String dueDate;

  ActionItem({
    required this.description,
    required this.assignee,
    required this.dueDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'assignee': assignee,
      'dueDate': dueDate,
    };
  }

  factory ActionItem.fromJson(Map<String, dynamic> json) {
    return ActionItem(
      description: json['description'] ?? '',
      assignee: json['assignee'] ?? '',
      dueDate: json['dueDate'] ?? '',
    );
  }

  ActionItem copyWith({
    String? description,
    String? assignee,
    String? dueDate,
  }) {
    return ActionItem(
      description: description ?? this.description,
      assignee: assignee ?? this.assignee,
      dueDate: dueDate ?? this.dueDate,
    );
  }
}

class MomData {
  String summary;
  List<String> participants;
  List<ActionItem> actionItems;
  List<String> decisions;

  MomData({
    required this.summary,
    required this.participants,
    required this.actionItems,
    required this.decisions,
  });

  Map<String, dynamic> toJson() {
    return {
      'summary': summary,
      'participants': participants,
      'actionItems': actionItems.map((item) => item.toJson()).toList(),
      'decisions': decisions,
    };
  }

  factory MomData.fromJson(Map<String, dynamic> json) {
    var rawActionItems = json['actionItems'] as List? ?? [];
    List<ActionItem> actions = rawActionItems
        .map((item) => ActionItem.fromJson(Map<String, dynamic>.from(item)))
        .toList();

    return MomData(
      summary: json['summary'] ?? '',
      participants: List<String>.from(json['participants'] ?? []),
      actionItems: actions,
      decisions: List<String>.from(json['decisions'] ?? []),
    );
  }

  factory MomData.empty() {
    return MomData(
      summary: '',
      participants: [],
      actionItems: [],
      decisions: [],
    );
  }

  MomData copyWith({
    String? summary,
    List<String>? participants,
    List<ActionItem>? actionItems,
    List<String>? decisions,
  }) {
    return MomData(
      summary: summary ?? this.summary,
      participants: participants ?? List.from(this.participants),
      actionItems: actionItems ?? List.from(this.actionItems),
      decisions: decisions ?? List.from(this.decisions),
    );
  }
}

class Meeting {
  final String id;
  String title;
  final DateTime date;
  final Duration duration;
  String transcript;
  MomData mom;

  Meeting({
    required this.id,
    required this.title,
    required this.date,
    required this.duration,
    required this.transcript,
    required this.mom,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date.toIso8601String(),
      'durationMs': duration.inMilliseconds,
      'transcript': transcript,
      'mom': mom.toJson(),
    };
  }

  factory Meeting.fromJson(Map<String, dynamic> json) {
    return Meeting(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Untitled Meeting',
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      duration: Duration(milliseconds: json['durationMs'] ?? 0),
      transcript: json['transcript'] ?? '',
      mom: json['mom'] != null
          ? MomData.fromJson(Map<String, dynamic>.from(json['mom']))
          : MomData.empty(),
    );
  }

  Meeting copyWith({
    String? title,
    String? transcript,
    MomData? mom,
  }) {
    return Meeting(
      id: id,
      title: title ?? this.title,
      date: date,
      duration: duration,
      transcript: transcript ?? this.transcript,
      mom: mom ?? this.mom.copyWith(),
    );
  }
}
