import 'dart:math' as math;

import 'package:flutter/material.dart';

enum WindMapLayer { standard, satellite }

class WindMapView extends StatelessWidget {
  const WindMapView({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.windDirectionDegrees,
    required this.windSpeedKph,
    required this.overlayColor,
    this.windInKph = true,
    this.zoom = 9,
    this.showMarker = true,
    this.markerColor = Colors.blueAccent,
    this.mapLayer = WindMapLayer.standard,
    this.animationPhase = 0.0,
  });

  final double latitude;
  final double longitude;
  final double windDirectionDegrees;
  final double windSpeedKph;
  final Color overlayColor;
  final bool windInKph;
  final int zoom;
  final bool showMarker;
  final Color markerColor;
  final WindMapLayer mapLayer;
  final double animationPhase;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: _StaticMap(
            latitude: latitude,
            longitude: longitude,
            zoom: zoom,
            mapLayer: mapLayer,
          ),
        ),
        Positioned.fill(
          child: CustomPaint(
            painter: _WindOverlayPainter(
              directionDegrees: windDirectionDegrees,
              speedKph: windSpeedKph,
              color: overlayColor,
              windInKph: windInKph,
              phase: animationPhase,
            ),
          ),
        ),
        if (showMarker)
          Center(
            child: _LocationMarker(
              color: markerColor,
              directionDegrees: windDirectionDegrees,
            ),
          ),
      ],
    );
  }
}

class _LocationMarker extends StatelessWidget {
  const _LocationMarker({
    required this.color,
    required this.directionDegrees,
  });

  final Color color;
  final double directionDegrees;

  @override
  Widget build(BuildContext context) {
    final angle = (directionDegrees - 90) * math.pi / 180;
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
        Transform.rotate(
          angle: angle,
          child: const Icon(
            Icons.navigation,
            color: Colors.white,
            size: 18,
          ),
        ),
      ],
    );
  }
}

class _StaticMap extends StatelessWidget {
  const _StaticMap({
    required this.latitude,
    required this.longitude,
    required this.zoom,
    required this.mapLayer,
  });

  final double latitude;
  final double longitude;
  final int zoom;
  final WindMapLayer mapLayer;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return _TileGrid(
          latitude: latitude,
          longitude: longitude,
          zoom: zoom,
          size: size,
          mapLayer: mapLayer,
        );
      },
    );
  }
}

class _TileGrid extends StatelessWidget {
  const _TileGrid({
    required this.latitude,
    required this.longitude,
    required this.zoom,
    required this.size,
    required this.mapLayer,
  });

  final double latitude;
  final double longitude;
  final int zoom;
  final Size size;
  final WindMapLayer mapLayer;

  static const double _tileSize = 256.0;

  @override
  Widget build(BuildContext context) {
    final center = _project(latitude, longitude, zoom);
    final centerTileX = (center.dx / _tileSize).floor();
    final centerTileY = (center.dy / _tileSize).floor();
    final offsetX = center.dx - centerTileX * _tileSize;
    final offsetY = center.dy - centerTileY * _tileSize;
    final originX = size.width / 2 - offsetX;
    final originY = size.height / 2 - offsetY;

    final tilesX = (size.width / _tileSize).ceil() + 2;
    final tilesY = (size.height / _tileSize).ceil() + 2;
    final startX = centerTileX - (tilesX / 2).floor();
    final startY = centerTileY - (tilesY / 2).floor();
    final max = 1 << zoom;

    final tiles = <Widget>[];
    for (int x = 0; x < tilesX; x++) {
      for (int y = 0; y < tilesY; y++) {
        final tileX = startX + x;
        final tileY = startY + y;
        if (tileY < 0 || tileY >= max) continue;
        final wrappedX = _wrap(tileX, max);
        final posX = originX + (tileX - centerTileX) * _tileSize;
        final posY = originY + (tileY - centerTileY) * _tileSize;
        tiles.add(
          Positioned(
            left: posX,
            top: posY,
            width: _tileSize,
            height: _tileSize,
            child: Image.network(
              _tileUrl(wrappedX, tileY, zoom, mapLayer),
              fit: BoxFit.cover,
              filterQuality: FilterQuality.low,
            ),
          ),
        );
      }
    }

    return ClipRect(
      child: Stack(children: tiles),
    );
  }

  Offset _project(double lat, double lon, int zoom) {
    final n = 1 << zoom;
    final x = (lon + 180.0) / 360.0 * n * _tileSize;
    final latRad = lat * math.pi / 180.0;
    final y = (1 -
            math.log(math.tan(latRad) + 1 / math.cos(latRad)) / math.pi) /
        2 *
        n *
        _tileSize;
    return Offset(x, y);
  }

  int _wrap(int value, int max) {
    final m = value % max;
    return m < 0 ? m + max : m;
  }

  String _tileUrl(int x, int y, int zoom, WindMapLayer layer) {
    switch (layer) {
      case WindMapLayer.satellite:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/'
            'World_Imagery/MapServer/tile/$zoom/$y/$x';
      case WindMapLayer.standard:
      default:
        return 'https://tile.openstreetmap.org/$zoom/$x/$y.png';
    }
  }
}

class _WindOverlayPainter extends CustomPainter {
  _WindOverlayPainter({
    required this.directionDegrees,
    required this.speedKph,
    required this.color,
    required this.windInKph,
    required this.phase,
  });

  final double directionDegrees;
  final double speedKph;
  final Color color;
  final bool windInKph;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    final speed = windInKph ? speedKph : speedKph / 1.60934;
    final length = (18 + (speed / 2)).clamp(18, 40).toDouble();
    final spacing = (size.shortestSide / 5).clamp(60.0, 120.0);
    final angle = (directionDegrees - 90) * math.pi / 180;
    final dir = Offset(math.cos(angle), math.sin(angle));
    final ortho = Offset(-dir.dy, dir.dx);

    final drift = (phase % 1.0) * spacing;
    final offset = dir * drift;
    for (double y = -spacing; y < size.height + spacing; y += spacing) {
      for (double x = -spacing; x < size.width + spacing; x += spacing) {
        final center = Offset(x + spacing / 2, y + spacing / 2) + offset;
        final start = center - dir * (length / 2);
        final end = center + dir * (length / 2);
        canvas.drawLine(start, end, paint);

        final headLength = length * 0.25;
        final headWidth = headLength * 0.6;
        final headBase = end - dir * headLength;
        final p1 = end;
        final p2 = headBase + ortho * (headWidth / 2);
        final p3 = headBase - ortho * (headWidth / 2);

        final path = Path()
          ..moveTo(p1.dx, p1.dy)
          ..lineTo(p2.dx, p2.dy)
          ..lineTo(p3.dx, p3.dy)
          ..close();
        canvas.drawPath(path, paint..style = PaintingStyle.fill);
        paint.style = PaintingStyle.stroke;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WindOverlayPainter oldDelegate) {
    return oldDelegate.directionDegrees != directionDegrees ||
        oldDelegate.speedKph != speedKph ||
        oldDelegate.color != color ||
        oldDelegate.windInKph != windInKph ||
        oldDelegate.phase != phase;
  }
}
