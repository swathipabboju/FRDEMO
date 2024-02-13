class PunchRecord {
  String? type;
  String? timestamp;
  String? location;

  PunchRecord(this.type, this.timestamp, this.location);

  // Convert PunchRecord to JSON
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'timestamp': timestamp,
      'location': location,
    };
  }

  // Create PunchRecord from JSON
  factory PunchRecord.fromJson(Map<String, dynamic> json) {
    return PunchRecord(
      json['type'],
      json['timestamp'],
      json['location'],
    );
  }
}
