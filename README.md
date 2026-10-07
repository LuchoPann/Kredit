<div align="center">

```
██╗  ██╗██████╗ ███████╗██████╗ ██╗████████╗
██║ ██╔╝██╔══██╗██╔════╝██╔══██╗██║╚══██╔══╝
█████╔╝ ██████╔╝█████╗  ██║  ██║██║   ██║
██╔═██╗ ██╔══██╗██╔══╝  ██║  ██║██║   ██║
██║  ██╗██║  ██║███████╗██████╔╝██║   ██║
╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═════╝ ╚═╝   ╚═╝
```

**Controla tus créditos y tarjetas en un solo lugar, sin conexión.**

![Versión](https://img.shields.io/badge/versión-1.0.0-white?style=flat-square&labelColor=000)
![Plataforma](https://img.shields.io/badge/Android-5.0%2B-white?style=flat-square&labelColor=000&logo=android&logoColor=white)
![Flutter](https://img.shields.io/badge/Flutter-3.x-white?style=flat-square&labelColor=000&logo=flutter&logoColor=white)
![Offline](https://img.shields.io/badge/100%25-offline-white?style=flat-square&labelColor=000)
![Sin cuenta](https://img.shields.io/badge/sin_cuenta-ni_registro-white?style=flat-square&labelColor=000)

</div>

---

## ¿Qué es Kredit?

Kredit es una app personal de gestión de créditos para Colombia. Reúne en un solo lugar tus tarjetas de crédito y cupos de tienda, calcula automáticamente intereses y cronogramas, y funciona completamente offline sin requerir cuenta ni registro.

No hay servidores. No hay publicidad. Tus datos no salen del teléfono.

---

## Tipos de crédito soportados

| Tipo | Descripción | Ejemplos |
|------|-------------|---------|
| **Tarjeta de crédito** | Crédito revolving con ciclo de facturación, cupo disponible y cuota mínima | Bancolombia, Davivienda, Nu, Falabella, Rappi Pay |
| **Cupo de tienda / app** | Compras a cuotas en almacenes o fintechs. Cronograma completo por compra | Totto, Lili Pink, Alkosto, Addi, Sistecrédito |

---

## Funcionalidades

- **Simulador financiero** — calcula el impacto de un abono extra o una compra nueva antes de ejecutarla. Estrategias Avalanche y Snowball.
- **Vista unificada** — deuda total, interés mensual estimado y próximos vencimientos en un vistazo.
- **Cronograma de cuotas** — proyección completa con estimación de mora si hay atraso.
- **Recordatorios locales** — notificaciones antes de cada corte y vencimiento, sin internet.
- **Bloqueo biométrico** — huella o Face ID opcional.
- **Respaldo JSON** — exportación e importación manual de datos.
- **14 colores de acento** — personalización visual completa.
- **Tema claro y oscuro** — con múltiples variantes.

---

## Privacidad

```
Sin cuenta      →  No se requiere correo, contraseña ni perfil
Sin conexión    →  Funciona 100% offline
Sin servidores  →  No existe backend de Kredit
Sin publicidad  →  No hay tracking ni analytics
Datos locales   →  Todo vive en el teléfono del usuario
```

---

## Instalación

### Descargar APK

1. Ve a la sección [**Releases**](../../releases) de este repositorio.
2. Descarga el archivo `kredit-v1.0.0.apk` de la última release.
3. En tu Android: **Ajustes → Seguridad → Instalar apps de fuentes desconocidas**.
4. Abre el APK descargado e instala.

> Requiere Android 5.0 (API 21) o superior.

### Compilar desde fuente

```bash
# Clonar
git clone https://github.com/TU_USUARIO/kredit.git
cd kredit

# Instalar dependencias
flutter pub get

# Ejecutar en modo debug
flutter run

# Generar APK release
flutter build apk --release
# → build/app/outputs/flutter-apk/app-release.apk
```

**Requisitos:** Flutter 3.x · Dart 3.x · Android SDK

---

## Stack técnico

| Capa | Tecnología |
|------|-----------|
| UI | Flutter (Dart) |
| Estado | Provider |
| Persistencia local | Drift (SQLite) |
| Notificaciones | flutter_local_notifications |
| Biometría | local_auth |
| Respaldo | path_provider + JSON |

---

## Changelog

El historial completo de cambios visible al usuario está en [`lib/data/changelog.dart`](lib/data/changelog.dart).

Versiones disponibles como release en GitHub: [ver releases](../../releases).

---

## Estructura del proyecto

```
lib/
├── data/
│   ├── models/          # CreditType, CommercialQuota, CardMovement…
│   └── changelog.dart   # Historial de versiones
├── domain/
│   └── card_calculator.dart
├── providers/           # CreditProvider, CommercialQuotasProvider…
├── screens/
│   ├── dashboard/
│   ├── credits/
│   ├── credit_detail/
│   ├── stats/           # Simulador
│   └── account/
├── services/
│   └── backup_service.dart
├── widgets/
└── main.dart
```

---

## Licencia

Uso personal. No se autoriza redistribución comercial sin permiso explícito del autor.

---

<div align="center">

Hecho en Colombia · 2026

</div>
