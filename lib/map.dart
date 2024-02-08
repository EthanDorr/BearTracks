import 'package:flutter/material.dart'; 
import 'package:flutter_map/flutter_map.dart'; 
import 'package:latlong2/latlong.dart'; 
  
class MapScreen extends StatefulWidget { 
  const MapScreen({super.key}); 
  
  @override 
  State<MapScreen> createState() => _MapScreenState(); 
} 
  
class _MapScreenState extends State<MapScreen> { 
  final MapController controller = MapController(); 
    
  // Change as per your need 
  LatLng latLng = const LatLng(32.827, -83.648);  
  
  @override 
  Widget build(BuildContext context) { 
    return FlutterMap( 
      mapController: controller, 
      options: MapOptions( 
        initialCenter: latLng, 
        initialZoom: 18, 
      ), 
      children: [
        TileLayer(
          urlTemplate: const String.fromEnvironment('PUBLIC_API_KEY')
        ), 
        MarkerLayer( 
          markers: [ 
            Marker( 
              point: latLng, 
              width: 60, 
              height: 60, 
              alignment: Alignment.topCenter, 
              child: Icon( 
                Icons.location_pin, 
                color: Colors.red.shade700, 
                size: 60, 
              ), 
            ), 
          ], 
        ),
      ], 
    ); 
  } 
} 