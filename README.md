# ChatBoy Voice

Aplicación móvil Flutter que permite conversar con ChatBoy IA usando texto y voz. El proyecto implementa cuatro modos de interacción (Push-to-Talk, Dictado, Chat abierto y Hotword) con integración al endpoint móvil de ChatBoy y soporte para síntesis y reproducción de audio.

## Características

- Conexión con el endpoint `https://<dominio>/wp-json/chatboyia/v1/chat/mobile` usando token Bearer configurable.
- Campos adicionales para seleccionar voz y Google TTS API Key.
- Reconocimiento de voz con resultados parciales en tiempo real y modos especializados.
- Reproducción de audio remoto o síntesis local en caso de ausencia de audio.
- Botón de micrófono flotante y arrastrable cuyo estado persiste entre sesiones.
- Persistencia de configuración y estado usando `shared_preferences`.
- Manejo básico de errores y estados del micrófono.

## Estructura principal

```
lib/
├── main.dart
├── models/
├── services/
├── screens/
├── viewmodels/
└── widgets/
```

## Configuración

1. Instala dependencias:
   ```bash
   flutter pub get
   ```
2. Proporciona token y endpoint desde el panel de ajustes dentro de la aplicación.
3. Opcionalmente configura la frase de activación, frase de terminación y voz preferida.

### Android

Tras clonar el repositorio, ejecuta el siguiente comando dentro de la carpeta `android/` para regenerar el Gradle Wrapper de forma local:

```bash
cd android
gradle wrapper
```

Esto descargará el `gradle-wrapper.jar` necesario para los comandos de `gradlew` sin añadir el binario al control de versiones.

## Ejecución

```bash
flutter run
```

La aplicación es compatible con Android 13+ e iOS 15+.
