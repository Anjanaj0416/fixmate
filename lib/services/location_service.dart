// lib/services/location_service.dart
import 'package:flutter/material.dart';

class LocationService {
  /// Get list of all Sri Lankan towns/cities matching the ML model dataset
  static List<String> getAllCities() {
    return [
      // Major Cities
      'Colombo',
      'Kandy',
      'Galle',
      'Negombo',
      'Jaffna',
      'Kurunegala',
      'Anuradhapura',
      'Matara',
      'Ratnapura',
      'Trincomalee',
      'Batticaloa',
      'Badulla',
      'Nuwara Eliya',
      'Ampara',
      'Vavuniya',
      'Mannar',
      'Polonnaruwa',
      'Hambantota',
      'Puttalam',
      'Kegalle',
      'Monaragala',
      'Kilinochchi',
      'Mullativu',

      // Colombo Suburbs
      'Koswatta',
      'Dehiwala',
      'Mount Lavinia',
      'Moratuwa',
      'Kotte',
      'Sri Jayawardenepura Kotte',
      'Nugegoda',
      'Maharagama',
      'Rajagiriya',
      'Battaramulla',
      'Malabe',
      'Kaduwela',
      'Pelawatta',
      'Thalawathugoda',
      'Homagama',
      'Kottawa',
      'Piliyandala',
      'Boralesgamuwa',
      'Athurugiriya',
      'Pannipitiya',

      // Western Province
      'Wattala',
      'Ja Ela',
      'Ja-Ela',
      'Kiribathgoda',
      'Kelaniya',
      'Gampaha',
      'Kalutara',
      'Panadura',
      'Beruwala',
      'Wadduwa',
      'Horana',
      'Matugama',
      'Avissawella',
      'Minuwangoda',
      'Divulapitiya',
      'Veyangoda',
      'Nittambuwa',

      // Other Cities and Towns
      'Matale',
      'Dambulla',
      'Chilaw',
      'Kalmunai',
      'Wattegama',
      'Balangoda',
      'Embilipitiya',
      'Tangalle',
      'Ambalantota',
      'Deniyaya',
      'Tissamaharama',
      'Haputale',
      'Bandarawela',
      'Wellawaya',
    ];
  }

  /// Search cities by query string
  static List<String> searchCities(String query) {
    if (query.isEmpty) return getAllCities();

    String lowerQuery = query.toLowerCase();
    return getAllCities()
        .where((city) => city.toLowerCase().contains(lowerQuery))
        .toList();
  }

  /// Get coordinates for a city (matching ML model dataset)
  static Map<String, double>? getCityCoordinates(String cityName) {
    final coordinates = <String, Map<String, double>>{
      'colombo': {'lat': 6.9271, 'lng': 79.8612},
      'kandy': {'lat': 7.2906, 'lng': 80.6337},
      'galle': {'lat': 6.0535, 'lng': 80.2210},
      'negombo': {'lat': 7.2084, 'lng': 79.8380},
      'jaffna': {'lat': 9.6615, 'lng': 80.0255},
      'kurunegala': {'lat': 7.4818, 'lng': 80.3609},
      'anuradhapura': {'lat': 8.3114, 'lng': 80.4037},
      'matara': {'lat': 5.9549, 'lng': 80.5550},
      'ratnapura': {'lat': 6.6828, 'lng': 80.3992},
      'trincomalee': {'lat': 8.5874, 'lng': 81.2152},
      'batticaloa': {'lat': 7.7310, 'lng': 81.6747},
      'badulla': {'lat': 6.9934, 'lng': 81.0550},
      'nuwara eliya': {'lat': 6.9497, 'lng': 80.7891},
      'ampara': {'lat': 7.2978, 'lng': 81.6722},
      'dehiwala': {'lat': 6.8560, 'lng': 79.8638},
      'mount lavinia': {'lat': 6.8374, 'lng': 79.8634},
      'moratuwa': {'lat': 6.7730, 'lng': 79.8816},
      'nugegoda': {'lat': 6.8649, 'lng': 79.8997},
      'maharagama': {'lat': 6.8482, 'lng': 79.9298},
      'gampaha': {'lat': 7.0873, 'lng': 80.0014},
      'kalutara': {'lat': 6.5854, 'lng': 79.9607},
      'matale': {'lat': 7.4675, 'lng': 80.6234},
      'dambulla': {'lat': 7.8742, 'lng': 80.6511},
      // Add more as needed
    };

    String normalizedCity = cityName.toLowerCase().trim();
    return coordinates[normalizedCity];
  }

  /// Show city picker dialog
  static Future<String?> showCityPicker(BuildContext context) async {
    String searchQuery = '';
    List<String> filteredCities = getAllCities();

    return await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Select Your Nearest Town'),
              content: Container(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search town/city...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value;
                          filteredCities = searchCities(value);
                        });
                      },
                    ),
                    SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filteredCities.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(filteredCities[index]),
                            onTap: () {
                              Navigator.pop(context, filteredCities[index]);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
