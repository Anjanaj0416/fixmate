// lib/services/ml_worker_converter.dart
// Converts MLWorker (from ML API) to WorkerModel (app model)

import '../models/worker_model.dart';
import '../services/ml_service.dart';

class MLWorkerConverter {
  /// Convert MLWorker to WorkerModel
  static WorkerModel convertToWorkerModel(MLWorker mlWorker) {
    // Split name into first and last name
    List<String> nameParts = mlWorker.workerName.split(' ');
    String firstName =
        nameParts.isNotEmpty ? nameParts.first : mlWorker.workerName;
    String lastName =
        nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    return WorkerModel(
      workerId: mlWorker.workerId,
      workerName: mlWorker.workerName,
      firstName: firstName,
      lastName: lastName,
      serviceType: mlWorker.serviceType,
      serviceCategory: mlWorker.serviceType,
      businessName:
          '$firstName\'s ${mlWorker.serviceType.replaceAll('_', ' ')} Service',

      // Location
      location: WorkerLocation(
        latitude: 0.0, // Will be updated from actual data
        longitude: 0.0,
        city: mlWorker.city,
        state: mlWorker.city, // Use city as state
        postalCode: '',
      ),

      // Ratings and stats
      rating: mlWorker.rating,
      experienceYears: mlWorker.experienceYears,
      jobsCompleted:
          mlWorker.experienceYears * 20, // Estimate based on experience
      successRate: mlWorker.rating * 20, // Convert 5-star to 100% scale

      // Pricing
      pricing: WorkerPricing(
        dailyWageLkr: mlWorker.dailyWageLkr.toDouble(),
        halfDayRateLkr: mlWorker.dailyWageLkr * 0.6,
        minimumChargeLkr: mlWorker.dailyWageLkr * 0.3,
        emergencyRateMultiplier: 1.5,
        overtimeHourlyLkr: mlWorker.dailyWageLkr / 8,
      ),

      // Availability
      availability: WorkerAvailability(
        availableToday: true,
        availableWeekends: true,
        emergencyService: mlWorker.rating >= 4.0,
        workingHours: '08:00 AM - 06:00 PM',
        responseTimeMinutes: 30,
      ),

      // Capabilities
      capabilities: WorkerCapabilities(
        toolsOwned: mlWorker.experienceYears >= 3,
        vehicleAvailable: mlWorker.experienceYears >= 5,
        certified: mlWorker.rating >= 4.5,
        insurance: mlWorker.rating >= 4.5,
        languages: ['English', 'Sinhala'],
      ),

      // Contact
      contact: WorkerContact(
        phoneNumber: mlWorker.phoneNumber,
        whatsappAvailable: true,
        email: mlWorker.email,
        website: null,
      ),

      // Profile
      profile: WorkerProfile(
        bio: mlWorker.bio,
        specializations: [mlWorker.serviceType],
        serviceRadiusKm:
            mlWorker.distanceKm * 2, // Double the distance as service radius
      ),

      // Metadata
      createdAt: DateTime.now(),
      lastActive: DateTime.now(),
      verified: mlWorker.rating >= 4.0,
    );
  }

  /// Convert list of MLWorkers to WorkerModels
  static List<WorkerModel> convertListToWorkerModels(List<MLWorker> mlWorkers) {
    return mlWorkers.map((mlWorker) => convertToWorkerModel(mlWorker)).toList();
  }
}
