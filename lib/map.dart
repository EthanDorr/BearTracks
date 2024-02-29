// ignore: unused_import
import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';

// ignore: unused_import
import 'package:bear_tracks/globals.dart';
import 'package:bear_tracks/gps.dart';


class MapScreen extends StatefulWidget {
  const MapScreen({super.key}); 

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  late final AnimatedMapController _controller = AnimatedMapController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
    curve: Curves.easeInOut,
  );
  bool isMapReady = false;
  Style? _style;
  bool isLocationEnabled = false;
  GPS gps = GPS();


  // A whole bunch of initialization.
  @override
  void initState() {
    super.initState();
    _initGPS();
    WidgetsFlutterBinding.ensureInitialized();
    _initStyle();
  }

  // Initialize style
  Future<void> _initStyle() async {
    _style = await _readStyle();
    setState(() {});
  }
  
  // Initialize GPS and create a location stream for the CurrentLocationMarker
  Future<void> _initGPS() async {
    await gps.init();
    gps.serviceStatusStream?.listen((serviceStatus) {
      setState(() {
        isLocationEnabled = gps.evaluateServiceStatus(serviceStatus);
      });
    });
    setState(() { // Initialize on first run
      isLocationEnabled = gps.evaluateServiceStatus(gps.serviceStatus);
    });
  }

  @override
  void dispose() {
    gps.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    log('Building...');
    if (_style == null) {
      return const Center(
        child: CircularProgressIndicator(
          color: mercerMercerOrange,
          backgroundColor: mercerDarkGray,
        ),
      );
    }
    log('got here');
    Widget map = _map(_style!);
    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (kDebugMode)
              Container(
                color: mercerDarkGray,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _debugStats(_controller.mapController)
                  ],
                ),
              ),
            Flexible(
              child: map,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _recenterUserOnMap(_controller),
        child: isLocationEnabled
          ? const Icon(Icons.my_location_sharp)
          : const Icon(Icons.location_disabled)
      ),
    );
  }

  Widget _map(Style style) {
    MapOptions mapOptions = MapOptions(
      initialCenter: gps.getInitialLatLng(),
      initialZoom: 18.0,
      minZoom: 17.0,
      maxZoom: 19.0,
      onMapReady: () {
        setState(() {
          isMapReady = true;
        });
      }
    );

    log('Building map...');
    return FlutterMap(
      mapController: _controller.mapController,
      options: mapOptions,
      children: [
        // TODO: Play with style
        VectorTileLayer(
          tileProviders: style.providers,
          theme: style.theme,
          sprites: style.sprites,
          tileOffset: TileOffset.mapbox,
          fileCacheTtl: const Duration(days: 2), // TODO: Increase in prod
          logCacheStats: true,
          layerMode: VectorTileLayerMode.vector,
          maximumZoom: mapOptions.maxZoom,
          cacheFolder: _getTempDirectory, // TODO: Check this is a good location
        ),
        CurrentLocationMarker( // imported from gps.dart
          isLocationEnabled: isLocationEnabled,
          positionStream: gps.positionStream,
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
  }

  Widget _debugStats(MapController mapController) {
    TextStyle debugTextStyle = const TextStyle(
      backgroundColor: mercerDarkGray,
      color: mercerLighterGray,
    );
    return Padding(
      padding: const EdgeInsets.only(
        top: 12,
        bottom: 12,
      ),
      child: StreamBuilder(
        stream: mapController.mapEventStream,
        builder: (context, snapshot) {
          return (isMapReady)
            ? Text(
                'Zoom: ${mapController.camera.zoom.toStringAsFixed(2)}      '
                'LatLng: ${mapController.camera.center.latitude.toStringAsFixed(4)}, '
                        '${mapController.camera.center.longitude.toStringAsFixed(4)}',
                style: debugTextStyle,
              )
            : Text(
              'Loading debug stats...',
              style: debugTextStyle,
            );
        }
      )
    );
  }

  Future<Style> _readStyle() async {
    return StyleReader(
      uri: '${const String.fromEnvironment('STYLE_URI')}?access_token={key}',
      apiKey: const String.fromEnvironment('PUBLIC_ACCESS_TOKEN')
    ).read();
  }

  Future<Directory> _getTempDirectory() async {
    final cacheDirectory = await getTemporaryDirectory();
    return cacheDirectory;
  }

  void _recenterUserOnMap(AnimatedMapController controller) async {
    if (await gps.isServiceStatusAndPermissionsEnabledGL(request: true)) {
      controller.centerOnPoint(gps.latlng ?? controller.mapController.camera.center);
    }
  }
}
