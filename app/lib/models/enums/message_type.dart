enum MessageType {
  text('text'),
  image('image');

  const MessageType(this.value);

  final String value;

  static MessageType fromString(String value) {
    return MessageType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => MessageType.text,
    );
  }
}
