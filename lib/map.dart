// ignore: unused_import
import 'dart:developer';

import 'package:dio_cache_interceptor_hive_store/dio_cache_interceptor_hive_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:flutter_map_cache/flutter_map_cache.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:bear_tracks/globals.dart';
import 'package:bear_tracks/gps.dart';



class MapScreen extends StatefulWidget {
  const MapScreen({super.key}); 

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  bool isLocationEnabled = false;
  LatLng initialLatLng = mercerLatLng;
  final AlignOnUpdate _alignPositionOnUpdate = AlignOnUpdate.never;
  late final AnimatedMapController controller;

  GPS gps = GPS();

  @override
  void initState() {
    super.initState();
    _initializeGPS();
    _initializeMapController();
  }

  void _initializeGPS() {
    isLocationEnabled = gps.evaluateServiceStatus(gps.serviceStatus);
    initialLatLng = gps.getInitialLatLng();

    gps.serviceStatusStream?.listen((status) {
      setState(() {
        isLocationEnabled = gps.evaluateServiceStatus(status);
      });
    });
  }

  void _initializeMapController() {
    controller = AnimatedMapController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    gps.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const factory = LocationMarkerDataStreamFactory();
    return Scaffold(
      body: FutureBuilder(
        future: Future.wait([gps.isLocationServicesEnabledGL(), getPath()]),
        //initialData: gps.serviceStatus,
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: mercerOrange,
                backgroundColor: mercerDarkGray,
              ),
            );
          }
          isLocationEnabled = snapshot.data![0];

          return FlutterMap(
            mapController: controller.mapController,
            options: MapOptions(
              initialCenter: initialLatLng,
              initialZoom: 18.0,
              minZoom: 16.0,
              maxZoom: 19.0,
            ),
            children: [
              TileLayer(
                urlTemplate: const String.fromEnvironment('PUBLIC_API_KEY'),
                tileProvider: CachedTileProvider(
                  maxStale: const Duration(days: 2),
                  store: HiveCacheStore(
                    snapshot.data![1],
                    hiveBoxName: 'HiveCacheStore'
                  )
                )
              ),
              if (isLocationEnabled)
                CurrentLocationLayer(
                  alignPositionOnUpdate: _alignPositionOnUpdate,
                  positionStream: factory.fromGeolocatorPositionStream(
                      stream: gps.positionStream,
                  ),
                ),
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    'OpenStreetMap contributors',
                    onTap: () => launchUrl(Uri.parse('https://openstreetmap.org/copyright')),
                  ),
                ],
                alignment: AttributionAlignment.bottomLeft,
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => recenterUserOnMap(),
        child: isLocationEnabled? const Icon(Icons.location_searching) : const Icon(Icons.location_disabled)   
      ),
    );
  }

  Future<String> getPath() async {
    final cacheDirectory = await getTemporaryDirectory();
    return cacheDirectory.path;
  }

  void recenterUserOnMap() async {
    if (await gps.isServiceStatusAndPermissionsEnabledGL(request: true)) {
      controller.centerOnPoint(gps.latlng ?? controller.mapController.camera.center);
    }
  }
}
