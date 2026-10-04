/// Registro de cambios visible al usuario por versión.
/// Agregar una entrada aquí y actualizar [currentVersion] cada release.
library changelog;

const String currentVersion = '0.9.0';

class VersionEntry {
  final String version;
  final String date;
  final List<ChangeItem> changes;

  const VersionEntry({
    required this.version,
    required this.date,
    required this.changes,
  });
}

class ChangeItem {
  final ChangeType type;
  final String description;

  const ChangeItem(this.type, this.description);
}

enum ChangeType { nuevo, mejora, correccion }

const List<VersionEntry> changelog = [
  VersionEntry(
    version: '0.9.0',
    date: 'Octubre 2026',
    changes: [
      ChangeItem(ChangeType.nuevo,
          'Respaldo automático: los archivos ahora se guardan en la carpeta Kredit/backups/ del almacenamiento principal del teléfono.'),
      ChangeItem(ChangeType.nuevo,
          'Configuración de hora para el respaldo automático.'),
      ChangeItem(ChangeType.nuevo,
          'Ícono personalizado de Kredit en la barra de notificaciones.'),
      ChangeItem(ChangeType.mejora,
          'Nueva pantalla de cuenta: diseño limpio con foto de perfil editable y acceso rápido a cada sección.'),
      ChangeItem(ChangeType.mejora,
          'Los diálogos de confirmación ahora se muestran como paneles deslizables desde abajo.'),
      ChangeItem(ChangeType.mejora,
          'La edición de tarjetas y cupos de tienda tiene ahora formularios separados adaptados a cada tipo.'),
      ChangeItem(ChangeType.mejora,
          'Mejoras visuales en el modo claro: colores más diferenciados entre variantes.'),
      ChangeItem(ChangeType.correccion,
          'Corregido error que impedía mostrar valores de días de pago fuera del rango del selector.'),
    ],
  ),
];
