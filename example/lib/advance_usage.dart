import 'package:flutter/material.dart';
import 'package:interactive_maps_marker/interactive_maps_marker.dart';

class AdvancedUsage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Advanced Usage'),
      ),
      body: Center(
        child: Text('Coming Soon'),
      ),
    );
  }
}

class StoreItem implements MarkerItem {
  @override
  int id;

  @override
  double latitude;

  @override
  double longitude;

  final String title;
  final String subTitle;
  final String image;
  final String details;

  StoreItem(
    this.image, {
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.title,
    required this.subTitle,
    required this.details,
  });
}
