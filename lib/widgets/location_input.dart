import 'dart:convert';

import 'package:favourite_places/helper/global.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;

class LocationInput extends StatefulWidget {
  const LocationInput({super.key});

  @override
  State<LocationInput> createState() => _LocationInputState();
}

class _LocationInputState extends State<LocationInput> {
  Location? _pickedLocation;
  var _isGettingLocation = false;

  // void _getCurrentLocation() async {
  //   Location location = Location();
  //
  //   bool serviceEnabled;
  //   PermissionStatus permissionGranted;
  //   LocationData locationData;
  //
  //   serviceEnabled = await location.serviceEnabled();
  //   if (!serviceEnabled) {
  //     serviceEnabled = await location.requestService();
  //     if (!serviceEnabled) {
  //       return;
  //     }
  //   }
  //
  //   permissionGranted = await location.hasPermission();
  //   if (permissionGranted == PermissionStatus.denied) {
  //     permissionGranted = await location.requestPermission();
  //     if (permissionGranted != PermissionStatus.granted) {
  //       return;
  //     }
  //   }
  //
  //   setState(() {
  //     _isGettingLocation = true;
  //   });
  //
  //   locationData = await location.getLocation();
  //
  //   final url = Uri.parse(
  //     'https://api.olamaps.io/places/v1/reverse-geocode?latlng=${locationData.latitude},${locationData.longitude}&api_key=$olaApiKey',
  //   );
  //   final headers = {'X-Request-Id': 'XXX'};
  //   final response = await http.get(url, headers: headers);
  //   final resData = json.decode(response.body);
  //   final address = resData['predictions'][0]['description'];
  //   print('Address= $address');
  //
  //   setState(() {
  //     _isGettingLocation = false;
  //   });
  // }
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

      // Step 3. Form request URL
      final url = Uri.parse(
        'https://api.olamaps.io/places/v1/reverse-geocode?latlng=${locationData.latitude},${locationData.longitude}&api_key=$olaApiKey',
      );

      // Step 4. Send request and parse response
      // final headers = {'X-Request-Id': 'XXX'};
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final resData = json.decode(response.body);
        String? address;
        print('response Data: $resData');
        // Step 5. Extract description from response
        if (resData['results'] != null &&
            resData['results'] is List &&
            resData['results'].isNotEmpty &&
            resData['results'][0]['formatted_address'] != null) {
          address = resData['results'][0]['formatted_address'];
          print('Address: $address');
        } else {
          print('No formatted_address found.');
        }

      } else {
        print('Failed to fetch location: ${response.statusCode}');
      }
    } catch (e) {
      print('Error during location fetch: $e');
    } finally {
      setState(() {
        _isGettingLocation = false;
      });
    }
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
