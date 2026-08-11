# 📱 Kredit - Control de Créditos y Cuotas para Android

¡Kredit está lista! Esta es una **Progressive Web App (PWA)** móvil diseñada con una interfaz premium para que lleves el control de tus deudas directamente en tu celular de forma fácil y cómoda.

---

## 🚀 Cómo abrir e instalar Kredit en tu celular desde Termux

Dado que estás desarrollando en **Termux**, puedes levantar un servidor web local en cuestión de segundos para abrir e instalar la app en tu teléfono Android.

### Paso 1: Inicia el Servidor Web
Ejecuta uno de los siguientes comandos en tu terminal de Termux (dentro de la carpeta de este proyecto `/Kredit`):

* **Si tienes Python instalado (Recomendado):**
  ```bash
  python -m http.server 8080
  ```

* **Si prefieres Node.js:**
  ```bash
  npx http-server -p 8080
  ```

### Paso 2: Abre la App en tu Celular
1. Abre tu navegador web favorito (se recomienda **Google Chrome** en Android para la mejor compatibilidad de PWA).
2. Entra a la siguiente dirección en el navegador:
   ```text
   http://localhost:8080
   ```

### Paso 3: Instala la App en Android (Agregar a Pantalla de Inicio)
Una vez abierta la aplicación en tu navegador:
1. Dirígete a la pestaña **Ajustes** en la esquina inferior derecha de la app.
2. Presiona el botón **Instalar** (o usa el menú de Chrome de 3 puntos en la esquina superior derecha y selecciona **"Instalar aplicación"** o **"Agregar a la pantalla principal"**).
3. ¡Listo! Se creará un icono llamado **Kredit** con su logotipo en el menú de aplicaciones de tu celular. Ahora podrás abrirla a pantalla completa sin barra de direcciones y funcionará incluso sin internet (offline).

---

## 🛠️ Estructura del Proyecto

* **[index.html](file:///data/data/com.termux/files/home/storage/downloads/MinijuegosTareaMiAmor/Kredit/index.html):** Contiene la estructura y vistas de la Single Page Application (SPA).
* **[css/style.css](file:///data/data/com.termux/files/home/storage/downloads/MinijuegosTareaMiAmor/Kredit/css/style.css):** Hoja de estilos con efectos de Glassmorphism, paleta de colores neon y adaptabilidad móvil.
* **[js/app.js](file:///data/data/com.termux/files/home/storage/downloads/MinijuegosTareaMiAmor/Kredit/js/app.js):** Lógica matemática de amortización, alertas de vencimiento, almacenamiento local (`localStorage`) e importación/exportación de respaldos.
* **[manifest.json](file:///data/data/com.termux/files/home/storage/downloads/MinijuegosTareaMiAmor/Kredit/manifest.json):** Archivo de manifiesto que indica a Android que es una PWA instalable.
* **[sw.js](file:///data/data/com.termux/files/home/storage/downloads/MinijuegosTareaMiAmor/Kredit/sw.js):** Service worker que cachea los archivos para que funcione sin conexión.
* **`icons/icon.jpg`:** Icono premium diseñado para Kredit.

---

## 💾 Respaldo y Seguridad
Tus datos se guardan de manera segura de forma local en tu celular (dentro de tu navegador) para total privacidad.
> [!IMPORTANT]
> Recuerda usar la opción **Exportar** dentro de la pestaña **Ajustes** cada cierto tiempo para descargar un archivo de respaldo. Si alguna vez borras el caché completo de tu navegador, podrás recuperar todos tus créditos al subir ese archivo con el botón **Importar**.
