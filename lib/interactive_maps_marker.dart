library interactive_maps_marker; // interactive_marker_list

import 'dart:async';
import 'dart:typed_data';

import "package:flutter/material.dart";
import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import './utils.dart';

class MarkerItem {
  final int id;
  final double latitude;
  final double longitude;

  MarkerItem({
    required this.id,
    required this.latitude,
    required this.longitude,
  });
}

class InteractiveMapsMarker extends StatefulWidget {
  final LatLng center;
  final double itemHeight;
  final double zoom;
  final List<MarkerItem> items;
  final IndexedWidgetBuilder itemContent;

  final IndexedWidgetBuilder? itemBuilder;
  final EdgeInsetsGeometry itemPadding;
  final Alignment contentAlignment;

  final bool zoomControlsEnabled;
  final bool myLocationEnabled;
  final bool myLocationButtonEnabled;

  InteractiveMapsMarker({
    Key? key,
    required this.items,
    this.itemBuilder,
    this.center = const LatLng(0.0, 0.0),
    required this.itemContent,
    this.itemHeight = 116,
    this.zoom = 12.0,
    this.itemPadding = const EdgeInsets.only(bottom: 80.0),
    this.contentAlignment = Alignment.bottomCenter,
    this.zoomControlsEnabled = true,
    this.myLocationEnabled = false,
    this.myLocationButtonEnabled = true,
  }) : super(key: key);

  @override
  InteractiveMapsMarkerState createState() => InteractiveMapsMarkerState();
}

class InteractiveMapsMarkerState extends State<InteractiveMapsMarker> {
  Completer<GoogleMapController> _controller = Completer();
  GoogleMapController? mapController;
  PageController pageController = PageController(viewportFraction: 0.9);

  Set<Marker>? markers;
  int currentIndex = 0;
  ValueNotifier selectedMarker = ValueNotifier<int>(-1);

  Uint8List? markerIcon;
  Uint8List? markerIconSelected;

  @override
  void initState() {
    rebuildMarkers(currentIndex);
    super.initState();
  }

  @override
  void didChangeDependencies() {
    rebuildMarkers(currentIndex);
    super.didChangeDependencies();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _controller.complete(controller);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      initialData: 0,
      builder: (context, snapshot) {
        return Stack(
          children: <Widget>[
            _buildMap(),
            Visibility(
              visible: widget.zoomControlsEnabled,
              child: Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: _buildZoomControls(context),
                ),
              ),
            ),
            Align(
              alignment: widget.contentAlignment,
              child: Padding(
                padding: widget.itemPadding,
                child: SizedBox(
                  height: widget.itemHeight,
                  child: PageView.builder(
                    itemCount: widget.items.length,
                    controller: pageController,
                    onPageChanged: _pageChanged,
                    itemBuilder: widget.itemBuilder ?? _buildItem,
                  ),
                ),
              ),
            )
          ],
        );
      },
    );
  }

  Widget _buildMap() {
    return Positioned.fill(
      child: ValueListenableBuilder(
        valueListenable: selectedMarker,
        builder: (context, value, child) {
          return GoogleMap(
            zoomControlsEnabled: false,
            myLocationEnabled: widget.myLocationEnabled,
            myLocationButtonEnabled: widget.myLocationButtonEnabled,
            markers: value == null ? {} : markers ?? {},
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: widget.center,
              zoom: widget.zoom,
            ),
          );
        },
      ),
    );
  }

  Widget _buildZoomControls(BuildContext context) {
    return Container(
      child: Container(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              backgroundColor:
                  Theme.of(context).buttonTheme.colorScheme!.background,
              child: IconButton(
                onPressed: () async {
                  var currentZoomLevel = await mapController!.getZoomLevel();
                  currentZoomLevel = currentZoomLevel + 1;
                  mapController!
                      .animateCamera(CameraUpdate.zoomTo(currentZoomLevel));
                },
                icon: Icon(
                  Icons.add,
                  color: Theme.of(context).buttonTheme.colorScheme!.onPrimary,
                ),
              ),
            ),
            SizedBox(
              height: 8,
            ),
            CircleAvatar(
              backgroundColor:
                  Theme.of(context).buttonTheme.colorScheme!.background,
              child: IconButton(
                onPressed: () async {
                  var currentZoomLevel = await mapController!.getZoomLevel();
                  currentZoomLevel = currentZoomLevel - 1;
                  mapController!
                      .animateCamera(CameraUpdate.zoomTo(currentZoomLevel));
                },
                icon: Icon(
                  Icons.remove,
                  color: Theme.of(context).buttonTheme.colorScheme!.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(context, i) {
    return Transform.scale(
      scale: i == currentIndex ? 1 : 0.9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10.0),
        child: Container(
          height: widget.itemHeight,
          decoration: BoxDecoration(
            color: Color(0xffffffff),
            boxShadow: [
              BoxShadow(
                offset: Offset(0.5, 0.5),
                color: Color(0xff000000).withOpacity(0.12),
                blurRadius: 20,
              ),
            ],
          ),
          child: widget.itemContent(context, i),
        ),
      ),
    );
  }

  void _pageChanged(int index) {
    setState(() => currentIndex = index);
    Marker? marker = markers?.elementAt(index);
    rebuildMarkers(index);

    mapController!
        .animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: marker!.position, zoom: 15),
      ),
    )
        .then((val) {
      setState(() {});
    });
  }

  Future<void> rebuildMarkers(int index) async {
    int current = widget.items.length > 0 ? widget.items[index].id : -1;

    if (markerIcon == null) {
      markerIcon = await getBytesFromAsset(
          'packages/interactive_maps_marker/assets/marker.png', 100);
    }
    if (markerIconSelected == null) {
      markerIconSelected = await getBytesFromAsset(
          'packages/interactive_maps_marker/assets/marker_selected.png', 100);
    }

    Set<Marker> _markers = Set<Marker>();

    widget.items.forEach((item) {
      _markers.add(
        Marker(
          markerId: MarkerId(item.id.toString()),
          position: LatLng(item.latitude, item.longitude),
          onTap: () {
            int tappedIndex =
                widget.items.indexWhere((element) => element.id == item.id);
            pageController.animateToPage(
              tappedIndex,
              duration: Duration(milliseconds: 300),
              curve: Curves.bounceInOut,
            );
            _pageChanged(tappedIndex);
          },
          icon: item.id == current
              ? BitmapDescriptor.fromBytes(markerIconSelected!)
              : BitmapDescriptor.fromBytes(markerIcon!),
        ),
      );
    });

    setState(() {
      markers = _markers;
    });
    selectedMarker.value = current;
  }
}
