import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flymap/logger.dart';

/// Minimal glTF-binary (.glb) mesh loader + software renderer for the flight
/// video's 3D plane.
///
/// Scope is deliberately tiny: triangles with POSITION/NORMAL/TEXCOORD_0,
/// node matrices, one baseColor texture. Primitives whose material is fully
/// transparent (the model's embedded collider mesh) are skipped, which is
/// also how the asset is "simplified" — no file rewrite needed.
///
/// Geometry is normalized at load: centered on the origin with the largest
/// ground-plane span scaled to 1, in glTF world space (Y up, fuselage along
/// X, wings along Z for this asset).
class PlaneModel {
  PlaneModel._({
    required this.positions,
    required this.normals,
    required this.uvs,
    required this.indices,
    required this.texture,
    required this.shadowSprite,
  }) : vertexCount = positions.length ~/ 3,
       triangleCount = indices.length ~/ 3;

  /// Pre-blurred ground silhouette, baked once at load. A per-frame layer
  /// blur cost ~50 ms/frame on device; drawing this sprite costs ~nothing.
  final ui.Image? shadowSprite;

  /// Sprite pixels per 1.0 of normalized model span (margin holds the blur).
  static const double shadowSpriteScale = 200;
  static const double shadowSpriteSize = 256;

  static const Logger _logger = Logger('PlaneModel');

  /// Normalized model-space vertex positions (x, y, z triplets).
  final Float32List positions;

  /// Unit normals (x, y, z triplets), rotated but not translated.
  final Float32List normals;

  /// Texture coordinates in texture-pixel space for [ui.ImageShader].
  final Float32List uvs;

  final Uint32List indices;
  final ui.Image? texture;
  final int vertexCount;
  final int triangleCount;

  void dispose() {
    texture?.dispose();
    shadowSprite?.dispose();
  }

  static Future<PlaneModel?> loadFromAsset(String assetPath) async {
    try {
      final data = await rootBundle.load(assetPath);
      return await _parseGlb(data.buffer.asUint8List());
    } catch (e, stack) {
      _logger.error('Failed to load plane model: $e\n$stack');
      return null;
    }
  }

  static Future<PlaneModel?> _parseGlb(Uint8List bytes) async {
    final data = ByteData.sublistView(bytes);
    if (bytes.length < 12 || data.getUint32(0, Endian.little) != 0x46546C67) {
      _logger.error('Not a GLB file');
      return null;
    }

    Map<String, dynamic>? gltf;
    Uint8List? bin;
    var offset = 12;
    while (offset + 8 <= bytes.length) {
      final chunkLength = data.getUint32(offset, Endian.little);
      final chunkType = data.getUint32(offset + 4, Endian.little);
      final chunkStart = offset + 8;
      if (chunkType == 0x4E4F534A) {
        gltf =
            jsonDecode(
                  utf8.decode(
                    bytes.sublist(chunkStart, chunkStart + chunkLength),
                  ),
                )
                as Map<String, dynamic>;
      } else if (chunkType == 0x004E4942) {
        bin = bytes.sublist(chunkStart, chunkStart + chunkLength);
      }
      offset = chunkStart + chunkLength + (-chunkLength) % 4;
    }
    if (gltf == null || bin == null) {
      _logger.error('GLB missing JSON or BIN chunk');
      return null;
    }

    final reader = _GltfReader(gltf, bin);

    // Flatten the default scene with composed node transforms.
    final positions = <double>[];
    final normals = <double>[];
    final uvs = <double>[];
    final indices = <int>[];

    void visit(int nodeIndex, _Mat4 parent) {
      final node = reader.nodes[nodeIndex] as Map<String, dynamic>;
      final world = parent.multiply(_Mat4.fromNode(node));
      final meshIndex = node['mesh'] as int?;
      if (meshIndex != null) {
        reader.appendMesh(
          meshIndex,
          world,
          positions: positions,
          normals: normals,
          uvs: uvs,
          indices: indices,
        );
      }
      for (final child in (node['children'] as List? ?? const [])) {
        visit(child as int, world);
      }
    }

    final sceneIndex = (gltf['scene'] as int?) ?? 0;
    final scenes = gltf['scenes'] as List? ?? const [];
    if (scenes.isEmpty) return null;
    final rootNodes =
        (scenes[sceneIndex] as Map<String, dynamic>)['nodes'] as List? ??
        const [];
    for (final root in rootNodes) {
      visit(root as int, _Mat4.identity());
    }
    if (positions.isEmpty || indices.isEmpty) {
      _logger.error('GLB contained no visible triangles');
      return null;
    }

    // Normalize: center on origin, largest ground span (x/z) -> 1.
    var minX = double.infinity, maxX = double.negativeInfinity;
    var minY = double.infinity, maxY = double.negativeInfinity;
    var minZ = double.infinity, maxZ = double.negativeInfinity;
    for (var i = 0; i < positions.length; i += 3) {
      minX = min(minX, positions[i]);
      maxX = max(maxX, positions[i]);
      minY = min(minY, positions[i + 1]);
      maxY = max(maxY, positions[i + 1]);
      minZ = min(minZ, positions[i + 2]);
      maxZ = max(maxZ, positions[i + 2]);
    }
    final centerX = (minX + maxX) / 2;
    final centerY = (minY + maxY) / 2;
    final centerZ = (minZ + maxZ) / 2;
    final span = max(max(maxX - minX, maxZ - minZ), 1e-9);
    final scale = 1 / span;
    final positionData = Float32List(positions.length);
    for (var i = 0; i < positions.length; i += 3) {
      positionData[i] = (positions[i] - centerX) * scale;
      positionData[i + 1] = (positions[i + 1] - centerY) * scale;
      positionData[i + 2] = (positions[i + 2] - centerZ) * scale;
    }

    final texture = await reader.decodeBaseColorTexture();
    final uvData = Float32List(uvs.length);
    final textureWidth = texture?.width.toDouble() ?? 1;
    final textureHeight = texture?.height.toDouble() ?? 1;
    for (var i = 0; i < uvs.length; i += 2) {
      uvData[i] = uvs[i] * textureWidth;
      uvData[i + 1] = uvs[i + 1] * textureHeight;
    }

    final shadowSprite = await _bakeShadowSprite(positionData, indices);

    _logger.log(
      'Plane model loaded: ${positionData.length ~/ 3} vertices, '
      '${indices.length ~/ 3} triangles, texture: ${texture != null}, '
      'shadow baked: ${shadowSprite != null}',
    );
    return PlaneModel._(
      positions: positionData,
      normals: Float32List.fromList(normals),
      uvs: uvData,
      indices: Uint32List.fromList(indices),
      texture: texture,
      shadowSprite: shadowSprite,
    );
  }

  /// Renders the ground silhouette (normalized x/z, up-axis dropped) into a
  /// small sprite with the blur baked in — the expensive layer blur runs
  /// exactly once instead of every frame.
  static Future<ui.Image?> _bakeShadowSprite(
    Float32List positions,
    List<int> indices,
  ) async {
    try {
      const size = shadowSpriteSize;
      const scale = shadowSpriteScale;
      final vertexCount = positions.length ~/ 3;
      final flat = Float32List(vertexCount * 2);
      for (var v = 0; v < vertexCount; v++) {
        flat[v * 2] = size / 2 + positions[v * 3] * scale;
        flat[v * 2 + 1] = size / 2 + positions[v * 3 + 2] * scale;
      }
      final colors = Int32List(vertexCount);
      colors.fillRange(0, vertexCount, 0xFF000000);
      final spriteIndices = Uint16List(indices.length);
      for (var i = 0; i < indices.length; i++) {
        spriteIndices[i] = indices[i];
      }

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(
        recorder,
        const ui.Rect.fromLTWH(0, 0, size, size),
      );
      canvas.saveLayer(
        const ui.Rect.fromLTWH(0, 0, size, size),
        ui.Paint()..imageFilter = ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      );
      final vertices = ui.Vertices.raw(
        ui.VertexMode.triangles,
        flat,
        colors: colors,
        indices: spriteIndices,
      );
      canvas.drawVertices(vertices, ui.BlendMode.dst, ui.Paint());
      canvas.restore();
      vertices.dispose();
      final picture = recorder.endRecording();
      final image = await picture.toImage(size.round(), size.round());
      picture.dispose();
      return image;
    } catch (e) {
      _logger.error('Shadow sprite bake failed: $e');
      return null;
    }
  }
}

class _GltfReader {
  _GltfReader(this.gltf, this.bin);

  final Map<String, dynamic> gltf;
  final Uint8List bin;

  List<dynamic> get nodes => gltf['nodes'] as List? ?? const [];

  void appendMesh(
    int meshIndex,
    _Mat4 world, {
    required List<double> positions,
    required List<double> normals,
    required List<double> uvs,
    required List<int> indices,
  }) {
    final mesh =
        (gltf['meshes'] as List)[meshIndex] as Map<String, dynamic>;
    for (final primitiveRaw in mesh['primitives'] as List) {
      final primitive = primitiveRaw as Map<String, dynamic>;
      if ((primitive['mode'] as int? ?? 4) != 4) continue;
      if (_isInvisible(primitive['material'] as int?)) continue;

      final attributes = primitive['attributes'] as Map<String, dynamic>;
      final positionAccessor = attributes['POSITION'] as int?;
      final indexAccessor = primitive['indices'] as int?;
      if (positionAccessor == null || indexAccessor == null) continue;

      final vertexBase = positions.length ~/ 3;
      final rawPositions = _readVec(positionAccessor, 3);
      for (var i = 0; i < rawPositions.length; i += 3) {
        final p = world.transformPoint(
          rawPositions[i],
          rawPositions[i + 1],
          rawPositions[i + 2],
        );
        positions.addAll(p);
      }

      final normalAccessor = attributes['NORMAL'] as int?;
      if (normalAccessor != null) {
        final rawNormals = _readVec(normalAccessor, 3);
        for (var i = 0; i < rawNormals.length; i += 3) {
          normals.addAll(
            world.transformDirection(
              rawNormals[i],
              rawNormals[i + 1],
              rawNormals[i + 2],
            ),
          );
        }
      } else {
        for (var i = 0; i < rawPositions.length; i += 3) {
          normals.addAll(const [0, 1, 0]);
        }
      }

      final uvAccessor = attributes['TEXCOORD_0'] as int?;
      if (uvAccessor != null) {
        uvs.addAll(_readVec(uvAccessor, 2));
      } else {
        for (var i = 0; i < rawPositions.length; i += 3) {
          uvs.addAll(const [0, 0]);
        }
      }

      for (final index in _readIndices(indexAccessor)) {
        indices.add(vertexBase + index);
      }
    }
  }

  bool _isInvisible(int? materialIndex) {
    if (materialIndex == null) return false;
    final material =
        (gltf['materials'] as List?)?[materialIndex] as Map<String, dynamic>?;
    final pbr = material?['pbrMetallicRoughness'] as Map<String, dynamic>?;
    final baseColor = pbr?['baseColorFactor'] as List?;
    // The bundled model carries an invisible collider mesh (alpha 0).
    return baseColor != null && (baseColor[3] as num) <= 0.01;
  }

  Future<ui.Image?> decodeBaseColorTexture() async {
    final materials = gltf['materials'] as List? ?? const [];
    for (final materialRaw in materials) {
      final material = materialRaw as Map<String, dynamic>;
      final pbr = material['pbrMetallicRoughness'] as Map<String, dynamic>?;
      final textureInfo = pbr?['baseColorTexture'] as Map<String, dynamic>?;
      if (textureInfo == null) continue;
      final textureIndex = textureInfo['index'] as int;
      final texture =
          (gltf['textures'] as List)[textureIndex] as Map<String, dynamic>;
      final imageIndex = texture['source'] as int?;
      if (imageIndex == null) continue;
      final image =
          (gltf['images'] as List)[imageIndex] as Map<String, dynamic>;
      final bufferView = image['bufferView'] as int?;
      if (bufferView == null) continue;
      final bytes = _bufferViewBytes(bufferView);
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      return frame.image;
    }
    return null;
  }

  Uint8List _bufferViewBytes(int index) {
    final view = (gltf['bufferViews'] as List)[index] as Map<String, dynamic>;
    final byteOffset = view['byteOffset'] as int? ?? 0;
    final byteLength = view['byteLength'] as int;
    return Uint8List.sublistView(bin, byteOffset, byteOffset + byteLength);
  }

  List<double> _readVec(int accessorIndex, int components) {
    final accessor =
        (gltf['accessors'] as List)[accessorIndex] as Map<String, dynamic>;
    assert(accessor['componentType'] == 5126, 'Expected float accessor');
    final count = accessor['count'] as int;
    final view =
        (gltf['bufferViews'] as List)[accessor['bufferView'] as int]
            as Map<String, dynamic>;
    final stride = view['byteStride'] as int? ?? components * 4;
    final base =
        (view['byteOffset'] as int? ?? 0) + (accessor['byteOffset'] as int? ?? 0);
    final data = ByteData.sublistView(bin);
    final result = List<double>.filled(count * components, 0);
    for (var i = 0; i < count; i++) {
      for (var c = 0; c < components; c++) {
        result[i * components + c] = data.getFloat32(
          base + i * stride + c * 4,
          Endian.little,
        );
      }
    }
    return result;
  }

  List<int> _readIndices(int accessorIndex) {
    final accessor =
        (gltf['accessors'] as List)[accessorIndex] as Map<String, dynamic>;
    final componentType = accessor['componentType'] as int;
    final count = accessor['count'] as int;
    final view =
        (gltf['bufferViews'] as List)[accessor['bufferView'] as int]
            as Map<String, dynamic>;
    final base =
        (view['byteOffset'] as int? ?? 0) + (accessor['byteOffset'] as int? ?? 0);
    final data = ByteData.sublistView(bin);
    final result = List<int>.filled(count, 0);
    for (var i = 0; i < count; i++) {
      switch (componentType) {
        case 5121: // ubyte
          result[i] = data.getUint8(base + i);
        case 5123: // ushort
          result[i] = data.getUint16(base + i * 2, Endian.little);
        case 5125: // uint
          result[i] = data.getUint32(base + i * 4, Endian.little);
        default:
          throw StateError('Unsupported index componentType $componentType');
      }
    }
    return result;
  }
}

/// Row-major 4x4 matrix (only what glTF node flattening needs).
class _Mat4 {
  _Mat4(this.m);

  final List<double> m; // 16 values, row-major

  factory _Mat4.identity() => _Mat4([
    1, 0, 0, 0, //
    0, 1, 0, 0, //
    0, 0, 1, 0, //
    0, 0, 0, 1, //
  ]);

  /// glTF stores `matrix` column-major; TRS nodes also supported.
  factory _Mat4.fromNode(Map<String, dynamic> node) {
    final matrix = node['matrix'] as List?;
    if (matrix != null) {
      return _Mat4([
        for (var r = 0; r < 4; r++)
          for (var c = 0; c < 4; c++) (matrix[c * 4 + r] as num).toDouble(),
      ]);
    }
    var result = _Mat4.identity();
    final translation = node['translation'] as List?;
    if (translation != null) {
      result = result.multiply(
        _Mat4([
          1, 0, 0, (translation[0] as num).toDouble(), //
          0, 1, 0, (translation[1] as num).toDouble(), //
          0, 0, 1, (translation[2] as num).toDouble(), //
          0, 0, 0, 1, //
        ]),
      );
    }
    final rotation = node['rotation'] as List?;
    if (rotation != null) {
      final x = (rotation[0] as num).toDouble();
      final y = (rotation[1] as num).toDouble();
      final z = (rotation[2] as num).toDouble();
      final w = (rotation[3] as num).toDouble();
      result = result.multiply(
        _Mat4([
          1 - 2 * (y * y + z * z), 2 * (x * y - z * w), 2 * (x * z + y * w), 0,
          2 * (x * y + z * w), 1 - 2 * (x * x + z * z), 2 * (y * z - x * w), 0,
          2 * (x * z - y * w), 2 * (y * z + x * w), 1 - 2 * (x * x + y * y), 0,
          0, 0, 0, 1,
        ]),
      );
    }
    final scale = node['scale'] as List?;
    if (scale != null) {
      result = result.multiply(
        _Mat4([
          (scale[0] as num).toDouble(), 0, 0, 0, //
          0, (scale[1] as num).toDouble(), 0, 0, //
          0, 0, (scale[2] as num).toDouble(), 0, //
          0, 0, 0, 1, //
        ]),
      );
    }
    return result;
  }

  _Mat4 multiply(_Mat4 other) {
    final a = m;
    final b = other.m;
    final out = List<double>.filled(16, 0);
    for (var r = 0; r < 4; r++) {
      for (var c = 0; c < 4; c++) {
        var sum = 0.0;
        for (var k = 0; k < 4; k++) {
          sum += a[r * 4 + k] * b[k * 4 + c];
        }
        out[r * 4 + c] = sum;
      }
    }
    return _Mat4(out);
  }

  List<double> transformPoint(double x, double y, double z) => [
    m[0] * x + m[1] * y + m[2] * z + m[3],
    m[4] * x + m[5] * y + m[6] * z + m[7],
    m[8] * x + m[9] * y + m[10] * z + m[11],
  ];

  List<double> transformDirection(double x, double y, double z) {
    final dx = m[0] * x + m[1] * y + m[2] * z;
    final dy = m[4] * x + m[5] * y + m[6] * z;
    final dz = m[8] * x + m[9] * y + m[10] * z;
    final length = sqrt(dx * dx + dy * dy + dz * dz);
    if (length < 1e-12) return const [0, 1, 0];
    return [dx / length, dy / length, dz / length];
  }
}

/// Draws a [PlaneModel] onto a canvas: yaw by heading, tilt by the camera
/// pitch, flat-shade, depth-sort, one `drawVertices` call.
class PlaneMeshPainter {
  PlaneMeshPainter(this.model, {this.modelYawOffset = 0})
    : _screenPositions = Float32List(model.vertexCount * 2),
      _shade = Float32List(model.vertexCount),
      _depth = Float32List(model.vertexCount),
      _colors = Int32List(model.vertexCount),
      _triangleOrder = List<int>.generate(
        model.triangleCount,
        (i) => i,
      ),
      _sortedIndices = Uint16List(model.indices.length),
      _baseIndices = Uint16List(model.indices.length) {
    for (var i = 0; i < model.indices.length; i++) {
      _baseIndices[i] = model.indices[i];
    }
  }

  /// Aligns the asset's nose with the painter's +X convention. Wrong nose on
  /// device? Cycle through 0, pi/2, pi, -pi/2.
  final double modelYawOffset;

  final PlaneModel model;
  final Float32List _screenPositions;
  final Float32List _shade;
  final Float32List _depth;
  final Int32List _colors;
  final List<int> _triangleOrder;
  final Uint16List _sortedIndices;
  final Uint16List _baseIndices;

  // --- 3x3 row-major matrix helpers -------------------------------------

  static List<double> _matMul(List<double> a, List<double> b) => [
    for (var r = 0; r < 3; r++)
      for (var c = 0; c < 3; c++)
        a[r * 3] * b[c] + a[r * 3 + 1] * b[3 + c] + a[r * 3 + 2] * b[6 + c],
  ];

  static List<double> _rotY(double a) => [
    cos(a), 0, sin(a), //
    0, 1, 0, //
    -sin(a), 0, cos(a), //
  ];

  static List<double> _rotX(double a) => [
    1, 0, 0, //
    0, cos(a), -sin(a), //
    0, sin(a), cos(a), //
  ];

  /// Camera tilt mapping model space (y up) to screen space (y down) —
  /// same math the map camera uses for the ground plane.
  static List<double> _tilt(double t) => [
    1, 0, 0, //
    0, -sin(t), cos(t), //
    0, cos(t), sin(t), //
  ];

  /// Full vertex rotation: mount the asset nose to +X, bank about the
  /// fuselage (wings dip alternately, like a plane on approach), yaw to the
  /// heading, tilt like the camera.
  List<double> _composeRotation({
    required double headingRad,
    required double tiltRad,
    required double bankRad,
    bool flattenToGround = false,
  }) {
    var m = _rotY(modelYawOffset);
    // In canonical space (nose +X, up Y, wings Z) the fuselage axis is X.
    m = _matMul(_rotX(bankRad), m);
    if (flattenToGround) {
      // Squash the up axis: the silhouette lies flat on the map.
      m = _matMul(const [1.0, 0, 0, 0, 0.0, 0, 0, 0, 1.0], m);
    }
    m = _matMul(_rotY(pi / 2 - headingRad), m);
    return _matMul(_tilt(tiltRad), m);
  }

  void paint(
    ui.Canvas canvas, {
    required ui.Offset center,
    required double headingRad,
    required double tiltRad,
    required double sizePx,
    double bankRad = 0,
    double opacity = 1,
  }) {
    final m = _composeRotation(
      headingRad: headingRad,
      tiltRad: tiltRad,
      bankRad: bankRad,
    );

    // Screen-space light from the upper left, slightly toward the viewer.
    const lx = -0.42, ly = -0.72, lz = 0.55;

    final positions = model.positions;
    final normals = model.normals;
    for (var v = 0; v < model.vertexCount; v++) {
      final px = positions[v * 3];
      final py = positions[v * 3 + 1];
      final pz = positions[v * 3 + 2];
      final sx = m[0] * px + m[1] * py + m[2] * pz;
      final sy = m[3] * px + m[4] * py + m[5] * pz;
      _screenPositions[v * 2] = center.dx + sx * sizePx;
      _screenPositions[v * 2 + 1] = center.dy + sy * sizePx;
      _depth[v] = m[6] * px + m[7] * py + m[8] * pz;

      final nx = normals[v * 3];
      final ny = normals[v * 3 + 1];
      final nz = normals[v * 3 + 2];
      final snx = m[0] * nx + m[1] * ny + m[2] * nz;
      final sny = m[3] * nx + m[4] * ny + m[5] * nz;
      final snz = m[6] * nx + m[7] * ny + m[8] * nz;
      final dot = snx * lx + sny * ly + snz * lz;
      // High ambient floor: modulate-blending can only darken the texture,
      // so shading stays a subtle accent rather than dimming the model.
      _shade[v] = 0.82 + 0.18 * max(0, dot.abs());
    }

    final alpha = (opacity.clamp(0.0, 1.0) * 255).round();
    for (var v = 0; v < model.vertexCount; v++) {
      final channel = (255 * _shade[v]).round().clamp(0, 255);
      _colors[v] =
          (alpha << 24) | (channel << 16) | (channel << 8) | channel;
    }

    // Painter's algorithm: far triangles first.
    final indices = model.indices;
    final triangleDepth = Float32List(model.triangleCount);
    for (var tri = 0; tri < model.triangleCount; tri++) {
      triangleDepth[tri] =
          _depth[indices[tri * 3]] +
          _depth[indices[tri * 3 + 1]] +
          _depth[indices[tri * 3 + 2]];
    }
    _triangleOrder.sort((a, b) => triangleDepth[a].compareTo(triangleDepth[b]));
    for (var i = 0; i < _triangleOrder.length; i++) {
      final tri = _triangleOrder[i];
      _sortedIndices[i * 3] = indices[tri * 3];
      _sortedIndices[i * 3 + 1] = indices[tri * 3 + 1];
      _sortedIndices[i * 3 + 2] = indices[tri * 3 + 2];
    }

    final texture = model.texture;
    final paint = ui.Paint();
    if (texture != null) {
      paint.shader = ui.ImageShader(
        texture,
        ui.TileMode.repeated,
        ui.TileMode.repeated,
        Float64List.fromList(const [
          1, 0, 0, 0, //
          0, 1, 0, 0, //
          0, 0, 1, 0, //
          0, 0, 0, 1, //
        ]),
      );
    }
    final vertices = ui.Vertices.raw(
      ui.VertexMode.triangles,
      _screenPositions,
      textureCoordinates: texture != null ? model.uvs : null,
      colors: _colors,
      indices: _sortedIndices,
    );
    canvas.drawVertices(
      vertices,
      texture != null ? ui.BlendMode.modulate : ui.BlendMode.dst,
      paint,
    );
    vertices.dispose();
  }

  /// Real ground shadow: the pre-baked blurred silhouette, rotated to the
  /// heading and foreshortened by the camera tilt. Costs one drawImageRect
  /// per frame (the blur was baked at model load).
  void paintShadow(
    ui.Canvas canvas, {
    required ui.Offset center,
    required double headingRad,
    required double tiltRad,
    required double sizePx,
    double bankRad = 0,
    double opacity = 1,
  }) {
    final sprite = model.shadowSprite;
    if (sprite == null) return;

    // Screen mapping of the flattened ground plane: yaw in ground coords
    // (RotY(a) == canvas.rotate(-a)), then the tilt squashes screen-y.
    final groundYaw = pi / 2 - headingRad + modelYawOffset;
    final squash = cos(tiltRad).abs().clamp(0.35, 1.0);
    final side =
        sizePx * PlaneModel.shadowSpriteSize / PlaneModel.shadowSpriteScale;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(1, squash);
    canvas.rotate(-groundYaw);
    canvas.drawImageRect(
      sprite,
      ui.Rect.fromLTWH(
        0,
        0,
        sprite.width.toDouble(),
        sprite.height.toDouble(),
      ),
      ui.Rect.fromCenter(center: ui.Offset.zero, width: side, height: side),
      ui.Paint()
        ..filterQuality = ui.FilterQuality.medium
        ..color = ui.Color.fromRGBO(0, 0, 0, opacity.clamp(0.0, 1.0)),
    );
    canvas.restore();
  }
}
