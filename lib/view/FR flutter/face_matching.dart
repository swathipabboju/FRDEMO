import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart' as tflite;

class FaceMatching {
  static const String MODEL_FILE = 'MobileFaceNet.tflite';
  static const int INPUT_IMAGE_SIZE = 112;
  static const double THRESHOLD = 0.8;

  late tflite.Interpreter interpreter;

  Future<double> loadModel(img1, img2) async {
    try {
      interpreter = await tflite.Interpreter.fromAsset('assets/$MODEL_FILE');
      print("interpreter loaded ${interpreter}");
      return compare(img1, img2);
      //return 0.1;
    } catch (e) {
      print('Error loading model: $e');
      return 0.0;
    }
  }

  Future<double> compare(File image1, File image2) async {
    List<int> bytes = await image1.readAsBytes();
    img.Image? imageFile = img.decodeImage(Uint8List.fromList(bytes));

    List<int> bytes1 = await image2.readAsBytes();
    img.Image? imageDownloadedFile =
        img.decodeImage(Uint8List.fromList(bytes1));

    img.Image bitmapScale1 = img.copyResize(imageFile!,
        width: INPUT_IMAGE_SIZE, height: INPUT_IMAGE_SIZE);
    img.Image bitmapScale2 = img.copyResize(imageDownloadedFile!,
        width: INPUT_IMAGE_SIZE, height: INPUT_IMAGE_SIZE);

    List<List<List<List<double>>>> datasets =
        _getTwoImageDatasets(bitmapScale1, bitmapScale2);
    List<List<double>> embeddings =
        List.generate(2, (index) => List.filled(192, 0.0));
    interpreter.run(datasets, embeddings);
    _L2Normalize(embeddings, 1e-10);
    return _evaluate(embeddings);
  }

  double _evaluate(List<List<double>> embeddings) {
    List<double> embeddings1 = embeddings[0];
    List<double> embeddings2 = embeddings[1];
    double dist = 0;

    for (int i = 0; i < 192; i++) {
      dist +=
          math.pow(embeddings1[i].toDouble() - embeddings2[i].toDouble(), 2);
    }

    double same = 0;
    for (int i = 0; i < 400; i++) {
      double threshold = 0.01 * (i + 1);
      if (dist < threshold) {
        same += 1.0 / 400;
      }
    }

    return same;
  }

  List<List<List<List<double>>>> _getTwoImageDatasets(
      img.Image bitmap1, img.Image bitmap2) {
    List<img.Image> bitmaps = [bitmap1, bitmap2];

    List<int> ddims = [bitmaps.length, INPUT_IMAGE_SIZE, INPUT_IMAGE_SIZE, 3];
    List<List<List<List<double>>>> datasets = List.generate(ddims[0], (index) {
      return List.generate(ddims[1], (index) {
        return List.generate(ddims[2], (index) {
          return List.generate(ddims[3], (index) => 0.0);
        });
      });
    });

    for (int i = 0; i < ddims[0]; i++) {
      img.Image bitmap = bitmaps[i];
      datasets[i] = _normalizeImage(bitmap);
    }
    return datasets;
  }

  void _L2Normalize(List<List<double>> embeddings, double epsilon) {
    for (int i = 0; i < embeddings.length; i++) {
      double sum = 0;
      for (int j = 0; j < embeddings[i].length; j++) {
        sum += math.pow(embeddings[i][j], 2);
      }
      double norm = math.sqrt(sum + epsilon);
      for (int j = 0; j < embeddings[i].length; j++) {
        embeddings[i][j] /= norm;
      }
    }
  }

  List<List<List<double>>> _normalizeImage(img.Image image) {
    List<List<List<double>>> result = List.generate(INPUT_IMAGE_SIZE, (index) {
      return List.generate(INPUT_IMAGE_SIZE, (index) {
        return List.generate(3, (index) => 0.0);
      });
    });

    for (int y = 0; y < INPUT_IMAGE_SIZE; y++) {
      for (int x = 0; x < INPUT_IMAGE_SIZE; x++) {
        img.Pixel pixel = image.getPixel(x, y);
        double r = (pixel.r / 255.0);
        double g = (pixel.g / 255.0);
        double b = (pixel.b / 255.0);
        result[y][x] = [r, g, b];
      }
    }
    print("result1111111111111111111111 ${result}");
    return result;
  }
}
