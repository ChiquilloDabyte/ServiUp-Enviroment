enum UserRole {
  client('client'),
  provider('provider');

  const UserRole(this.value);

  final String value;

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => UserRole.client,
    );
  }

  String get label => switch (this) {
        UserRole.client => 'Cliente',
        UserRole.provider => 'Prestador',
      };
}
