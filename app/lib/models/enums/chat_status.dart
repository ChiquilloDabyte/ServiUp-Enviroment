enum ChatStatus {
  active('active'),
  readOnly('read_only');

  const ChatStatus(this.value);

  final String value;

  static ChatStatus fromString(String value) {
    return ChatStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => ChatStatus.active,
    );
  }
}
