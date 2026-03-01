import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class MapboxTestScreen extends StatefulWidget {
  const MapboxTestScreen({super.key});

  @override
  State<MapboxTestScreen> createState() => _MapboxTestScreenState();
}

class _MapboxTestScreenState extends State<MapboxTestScreen> {

  MapboxMap? mapboxMap;

  @override
  void initState() {
    super.initState();
    MapboxOptions.setAccessToken("");
  }

  void _onMapCreated(MapboxMap mapboxMap) {
    this.mapboxMap = mapboxMap;

    mapboxMap.loadStyleURI(MapboxStyles.MAPBOX_STREETS);
  }

  @override
  Widget build(BuildContext context) {

    print("🚨 MAPBOX TEST SCREEN BUILD");

    return Scaffold(
      body: MapWidget(
        onMapCreated: _onMapCreated,
      ),
    );
  }
}