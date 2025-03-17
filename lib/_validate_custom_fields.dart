/// Validates custom fields according to the Atlas schema
/// Returns a list of error messages if validation fails, empty list if valid
List<String> validateCustomFields(Map<String, dynamic>? customFields) {
  if (customFields == null) return [];

  List<String> errors = [];

  customFields.forEach((key, value) {
    // Skip null values as they are allowed
    if (value == null) return;

    // Text field validation
    if (value is String) {
      return;
    }

    // Number field validation
    if (value is num) {
      return;
    }

    // Multi field validation (array of strings)
    if (value is List) {
      if (value.every((item) => item is String)) {
        return;
      }
      errors.add('"$key" must be a list of strings');
      return;
    }

    // URL field validation
    if (value is Map) {
      if (value.containsKey('url') &&
          value.containsKey('label') &&
          value['url'] is String &&
          value['label'] is String) {
        return;
      }

      // Address field validation - all fields are optional
      final addressFields = ['street1', 'street2', 'city', 'state', 'zipCode', 'country'];
      final addressErrors = <String>[];
      for (var field in addressFields) {
        if (value.containsKey(field) && value[field] is! String) {
          addressErrors.add('"$field" must be a string');
        }
      }
      if (addressErrors.isNotEmpty) {
        errors.add('"$key" fields must be strings: ${addressErrors.join(", ")}');
        return;
      }
      if (value.keys.any((key) => addressFields.contains(key))) {
        return;
      }

      errors.add('"$key" has invalid structure. Expected format:\n'
          '\tFor URL: {"url": "string", "label": "string"}\n'
          '\tFor Address: {"street1": "string", "street2": "string", "city": "string", "state": "string", "zipCode": "string", "country": "string"}');
      return;
    }

    errors.add('"$key" has invalid type: ${value.runtimeType}');
  });

  return errors;
}
