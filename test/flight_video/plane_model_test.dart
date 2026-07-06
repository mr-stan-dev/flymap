import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/domain/usecase/generate_flight_video_use_case.dart';
import 'package:flymap/ui/screens/flight_video/rendering/plane_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled airplane GLB parses and normalizes', () async {
    final model = await PlaneModel.loadFromAsset(
      GenerateFlightVideoUseCase.planeModelAssetPath,
    );
    expect(model, isNotNull);
    expect(model!.vertexCount, greaterThan(100));
    expect(model.triangleCount, greaterThan(100));
    expect(model.texture, isNotNull);
    expect(model.normals.length, model.vertexCount * 3);
    expect(model.uvs.length, model.vertexCount * 2);

    // Geometry is normalized: centered, largest ground span == 1.
    var minX = double.infinity, maxX = double.negativeInfinity;
    var minZ = double.infinity, maxZ = double.negativeInfinity;
    for (var i = 0; i < model.positions.length; i += 3) {
      final x = model.positions[i];
      final z = model.positions[i + 2];
      if (x < minX) minX = x;
      if (x > maxX) maxX = x;
      if (z < minZ) minZ = z;
      if (z > maxZ) maxZ = z;
    }
    final span = [maxX - minX, maxZ - minZ].reduce((a, b) => a > b ? a : b);
    expect(span, closeTo(1.0, 0.01));
    expect((minX + maxX) / 2, closeTo(0, 0.01));

    // All indices reference valid vertices.
    for (final index in model.indices) {
      expect(index, lessThan(model.vertexCount));
    }
    model.dispose();
  });
}
