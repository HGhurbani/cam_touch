// lib/core/models/pigeon_user_details.dart
// Simple model to represent user details returned via Pigeon
// Adjust fields as necessary to match the native implementation.

class PigeonUserDetails {
  final String id;
  final String email;
  final String name;

  PigeonUserDetails({required this.id, required this.email, required this.name});

  /// Creates an instance from the List format returned by a Pigeon channel.
  static PigeonUserDetails decode(List<Object?> data) {
    return PigeonUserDetails(
      id: data.isNotEmpty ? data[0] as String? ?? '' : '',
      email: data.length > 1 ? data[1] as String? ?? '' : '',
      name: data.length > 2 ? data[2] as String? ?? '' : '',
    );
  }
}

/// Helper to safely convert the dynamic value coming from the platform channel
/// into a [PigeonUserDetails] object. This avoids `List<Object>` casting errors.
PigeonUserDetails? parsePigeonUserDetails(Object? result) {
  if (result is PigeonUserDetails) return result;
  if (result is List<Object?>) {
    return PigeonUserDetails.decode(result);
  }
  return null;
}
