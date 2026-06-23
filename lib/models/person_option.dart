/// A simple class to represent a person option in autocomplete widgets.
/// Using a class instead of Dart records because the Dart compiler's
/// WidgetCallSiteTransformer crashes when record types are used as
/// generic parameters for widgets like Autocomplete.
class PersonOption {
  final int? id;
  final String name;

  const PersonOption({required this.id, required this.name});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonOption &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;

  @override
  String toString() => 'PersonOption(id: $id, name: $name)';
}
