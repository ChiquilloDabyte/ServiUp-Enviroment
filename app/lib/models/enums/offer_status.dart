enum OfferStatus {
  pending('pending'),
  accepted('accepted'),
  rejected('rejected'),
  superseded('superseded');

  const OfferStatus(this.value);

  final String value;

  static OfferStatus fromString(String value) {
    return OfferStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => OfferStatus.pending,
    );
  }

  String get label => switch (this) {
    OfferStatus.pending => 'Pendiente',
    OfferStatus.accepted => 'Aceptada',
    OfferStatus.rejected => 'Rechazada',
    OfferStatus.superseded => 'Reemplazada',
  };
}
