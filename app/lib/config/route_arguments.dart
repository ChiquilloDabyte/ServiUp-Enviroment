/// Presentation-only arguments for opening a request location without placing
/// exact coordinates in the route URL.
class RequestLocationMapArgs {
  const RequestLocationMapArgs({
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  final double latitude;
  final double longitude;
  final String address;
}
