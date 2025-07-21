import 'dart:convert';

import 'package:favourite_places/helper/global.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;

import '../models/place.dart';

class LocationInput extends StatefulWidget {
  const LocationInput({super.key, required this.onSelectedLocation});

  final void Function(PlaceLocation location) onSelectedLocation;

  @override
  State<LocationInput> createState() => _LocationInputState();
}

class _LocationInputState extends State<LocationInput> {
  PlaceLocation? _pickedLocation;
  var _isGettingLocation = false;
  late double lat;
  late double lng;
  var address;

  String get locationImage {
    if (_pickedLocation == null) {
      return '';
    }
    final lat = _pickedLocation!.latitude;
    final lng = _pickedLocation!.longitude;
    return 'https://api.olamaps.io/tiles/v1/styles/default-light-standard/static/auto/600x300.png?marker=$lng,$lat|green|scale:0.5|offset:2,-4&api_key=$olaApiKey';
  }

  void _getCurrentLocation() async {
    final location = Location();

    // Step 1. Check location service and permissions
    if (!await location.serviceEnabled()) {
      if (!await location.requestService()) return;
    }

    if (await location.hasPermission() == PermissionStatus.denied) {
      if (await location.requestPermission() != PermissionStatus.granted)
        return;
    }

    setState(() {
      _isGettingLocation = true;
    });

    try {
      // Step 2. Get current location
      final locationData = await location.getLocation();
      lat = locationData.latitude!;
      lng = locationData.longitude!;

      // if(lat == null || lng == null){
      //   return;
      // }
      // Step 3. Form request URL
      final url = Uri.parse(
        'https://api.olamaps.io/places/v1/reverse-geocode?latlng=$lat,$lng&api_key=$olaApiKey',
      );

      // Step 4. Send request and parse response
      // final headers = {'X-Request-Id': 'XXX'};
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final resData = json.decode(response.body);
        address = resData['results'][0]['formatted_address'];
        print('Adress: $address');
      } else {
        print('Failed to fetch location: ${response.statusCode}');
      }
    } catch (e) {
      print('Error during location fetch: $e');
    }

    setState(() {
      _pickedLocation = PlaceLocation(
        latitude: lat,
        longitude: lng,
        address: address,
      );
      _isGettingLocation = false;
    });

    widget.onSelectedLocation(_pickedLocation!);
  }

  @override
  Widget build(BuildContext context) {
    Widget previewContent = Text(
      'No location chosen',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );

    if (_pickedLocation != null) {
      previewContent = Image.network(
        locationImage,
        fit: BoxFit.cover,
        height: double.infinity,
        width: double.infinity,
      );
    }

    if (_isGettingLocation) {
      previewContent = const CircularProgressIndicator();
    }

    return Column(
      children: [
        Container(
          alignment: Alignment.center,
          height: 170,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(
              width: 1,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: .2),
            ),
          ),
          child: previewContent,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton.icon(
              onPressed: _getCurrentLocation,
              label: const Text('Get Current Location'),
              icon: const Icon(Icons.location_on),
            ),
            TextButton.icon(
              onPressed: () {},
              label: const Text('Select on Map'),
              icon: const Icon(Icons.map),
            ),
          ],
        ),
      ],
    );
  }
}

// final data = json.decode(response.body); // make sure response.statusCode == 200
//
// String? address;
//
// if (data['results'] != null &&
// data['results'] is List &&
// data['results'].isNotEmpty &&
// data['results'][0]['formatted_address'] != null) {
// address = data['results'][0]['formatted_address'];
// print('Address: $address');
// } else {
// print('No formatted_address found.');
// }
