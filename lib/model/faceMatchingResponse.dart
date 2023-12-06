class FaceMatchingResponse {
  List<Result>? result;
  String? message;
  String? code;

  FaceMatchingResponse({this.result, this.message, this.code});

  FaceMatchingResponse.fromJson(Map<String, dynamic> json) {
    if (json['result'] != null) {
      result = <Result>[];
      json['result'].forEach((v) {
        result!.add(new Result.fromJson(v));
      });
    }
    message = json['message'];
    code = json['code'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.result != null) {
      data['result'] = this.result!.map((v) => v.toJson()).toList();
    }
    data['message'] = this.message;
    data['code'] = this.code;
    return data;
  }
}

class Result {
  SourceImageFace? sourceImageFace;
  List<FaceMatches>? faceMatches;

  Result({this.sourceImageFace, this.faceMatches});

  Result.fromJson(Map<String, dynamic> json) {
    sourceImageFace = json['source_image_face'] != null
        ? new SourceImageFace.fromJson(json['source_image_face'])
        : null;
    if (json['face_matches'] != null) {
      faceMatches = <FaceMatches>[];
      json['face_matches'].forEach((v) {
        faceMatches!.add(new FaceMatches.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.sourceImageFace != null) {
      data['source_image_face'] = this.sourceImageFace!.toJson();
    }
    if (this.faceMatches != null) {
      data['face_matches'] = this.faceMatches!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class SourceImageFace {
  Box? box;

  SourceImageFace({this.box});

  SourceImageFace.fromJson(Map<String, dynamic> json) {
    box = json['box'] != null ? new Box.fromJson(json['box']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.box != null) {
      data['box'] = this.box!.toJson();
    }
    return data;
  }
}

class Box {
  dynamic probability;
  int? xMax;
  int? yMax;
  int? xMin;
  int? yMin;

  Box({this.probability, this.xMax, this.yMax, this.xMin, this.yMin});

  Box.fromJson(Map<String, dynamic> json) {
    probability = json['probability'];
    xMax = json['x_max'];
    yMax = json['y_max'];
    xMin = json['x_min'];
    yMin = json['y_min'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['probability'] = (this.probability);
    data['x_max'] = this.xMax;
    data['y_max'] = this.yMax;
    data['x_min'] = this.xMin;
    data['y_min'] = this.yMin;
    return data;
  }
}

class FaceMatches {
  Box? box;
  double? similarity;

  FaceMatches({this.box, this.similarity});

  FaceMatches.fromJson(Map<String, dynamic> json) {
    box = json['box'] != null ? new Box.fromJson(json['box']) : null;
    similarity = json['similarity'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.box != null) {
      data['box'] = this.box!.toJson();
    }
    data['similarity'] = this.similarity;
    return data;
  }
}
