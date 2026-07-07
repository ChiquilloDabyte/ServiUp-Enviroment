enum RequestStatus {
  open('open'),
  accepted('accepted'),
  inProgress('in_progress'),
  completed('completed'),
  cancelled('cancelled');

  const RequestStatus(this.value);

  final String value;

  static RequestStatus fromString(String value) {
    return RequestStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => RequestStatus.open,
    );
  }

  String get label => switch (this) {
        RequestStatus.open => 'Abierta',
        RequestStatus.accepted => 'Aceptada',
        RequestStatus.inProgress => 'En progreso',
        RequestStatus.completed => 'Completada',
        RequestStatus.cancelled => 'Cancelada',
      };

  bool get isActive =>
      this == RequestStatus.open ||
      this == RequestStatus.accepted ||
      this == RequestStatus.inProgress;
}
