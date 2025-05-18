
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_place/google_place.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final String googleApiKey = dotenv.env['GOOGLE_API_KEY']!;

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  late GoogleMapController _mapController;
  LatLng? _pickedLocation;
  String? _pickedAddress;
  late GooglePlace googlePlace;
  List<AutocompletePrediction> predictions = [];
  final TextEditingController _searchController = TextEditingController();

  final CameraPosition _initialPosition = const CameraPosition(
    target: LatLng(48.3794, 31.1656), // Центр України
    zoom: 5.5,
  );

  @override
  void initState() {
    super.initState();
    googlePlace = GooglePlace(googleApiKey);
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  Future<void> _selectLocation(LatLng position) async {
    setState(() => _pickedLocation = position);

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          _pickedAddress = '${place.locality ?? ''}, ${place.country ?? ''}';
        });
      }
    } catch (e) {
      debugPrint('❌ Геокодування не вдалося: $e');
    }
  }

  void _searchAutocomplete(String query) async {
    if (query.isNotEmpty) {
      var result = await googlePlace.autocomplete.get(
        query,
        language: 'uk',
        components: [Component('country', 'ua')],
      );
      if (result != null && result.predictions != null) {
        setState(() {
          predictions = result.predictions!;
        });
      }
    } else {
      setState(() => predictions = []);
    }
  }

  Future<void> _selectPlace(String placeId) async {
    var detail = await googlePlace.details.get(placeId);
    if (detail != null && detail.result != null) {
      final loc = detail.result!.geometry!.location;
      if (loc != null) {
        final latLng = LatLng(loc.lat!, loc.lng!);
        _mapController.animateCamera(CameraUpdate.newLatLng(latLng));
        _selectLocation(latLng);
        setState(() {
          predictions = [];
          _searchController.clear();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Оберіть локацію')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              onChanged: _searchAutocomplete,
              decoration: InputDecoration(
                hintText: 'Введіть населений пункт',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          if (predictions.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: predictions.length,
                itemBuilder: (context, index) {
                  final prediction = predictions[index];
                  return ListTile(
                    leading: const Icon(Icons.location_on),
                    title: Text(prediction.description ?? ''),
                    onTap: () => _selectPlace(prediction.placeId!),
                  );
                },
              ),
            )
          else
            Expanded(
              child: Stack(
                children: [
                  GoogleMap(
                    onMapCreated: _onMapCreated,
                    initialCameraPosition: _initialPosition,
                    onTap: _selectLocation,
                    markers: _pickedLocation == null
                        ? {}
                        : {
                            Marker(
                              markerId: const MarkerId('picked'),
                              position: _pickedLocation!,
                            ),
                          },
                  ),
                  if (_pickedAddress != null)
                    Positioned(
                      bottom: 100,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(color: Colors.black26, blurRadius: 6),
                          ],
                        ),
                        child: Text(
                          _pickedAddress!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: _pickedLocation != null
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.pop(context, {
                  'address': _pickedAddress,
                  'lat': _pickedLocation!.latitude,
                  'lng': _pickedLocation!.longitude,
                });
              },
              label: const Text('Підтвердити'),
              icon: const Icon(Icons.check),
            )
          : null,
    );
  }
}
