class MaterialValidationController {
  static Future<bool> validate(
    String containerCode,
    String visualAidCode,
    String finalLabelCode,
  ) async {
    // 1. Verificar si hay campos vacíos (automáticamente NG)
    if (containerCode.isEmpty ||
        visualAidCode.isEmpty ||
        finalLabelCode.isEmpty) {
      return false;
    }

    // 2. Verificar formatos correctos (C- y V-)
    final containerValid =
        containerCode.startsWith('C-') && containerCode.length > 2;
    final visualAidValid =
        visualAidCode.startsWith('V-') && visualAidCode.length > 2;

    if (!containerValid || !visualAidValid) {
      return false;
    }

    // 3. Extraer códigos base
    final containerBase = containerCode.substring(2);
    final visualAidBase = visualAidCode.substring(2);

    // 4. Verificar coincidencia de códigos base
    if (containerBase != visualAidBase) {
      return false;
    }

    // 5. Verificar que el código base esté en la etiqueta final
    return finalLabelCode.contains(containerBase);
  }
}
