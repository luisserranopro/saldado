# Saldado

**Gastos compartidos, cuentas claras.** App en Flutter para apuntar los gastos
de un grupo (un viaje, el piso compartido, una cena…) y saber quién debe a
quién con el menor número de pagos posible.

Funciona sin conexión y sin cuentas: una persona lleva las cuentas del grupo
en su móvil y comparte el resumen por WhatsApp.

## Qué hace

- **Grupos** con nombre, moneda (€, $, £, MXN, CHF) y personas.
- **Gastos** con concepto, importe, quién pagó, fecha y categoría.
  - Reparto **a partes iguales** entre quien elijas, o por **importes exactos**.
- **Saldos**: cuánto ha pagado cada uno, cuánto le correspondía y si le deben o debe.
- **Cómo saldar**: calcula las transferencias mínimas para quedar en paz.
  «Marcar como pagado» las registra (con opción de deshacer).
- **Compartir** el resumen por WhatsApp o copiarlo.

## Puesta en marcha

1. Descomprime y entra en la carpeta:
   ```
   cd saldado
   ```
2. Genera las carpetas de cada plataforma (no toca `lib/` ni `pubspec.yaml`):
   ```
   flutter create --org work.alcancia --project-name saldado --platforms android,ios,web .
   ```
   El identificador de la app será `work.alcancia.saldado`.
3. Dependencias, iconos y pantalla de arranque:
   ```
   flutter pub get
   dart run flutter_launcher_icons
   dart run flutter_native_splash:create
   dart run sqflite_common_ffi_web:setup
   ```
   - `flutter_launcher_icons` crea los iconos de Android (incluido el
     adaptativo), iOS y web a partir de `assets/icon/`.
   - `flutter_native_splash` crea la pantalla verde con el logo que se ve
     mientras arranca la app.
   - El último comando copia en `web/` los archivos que necesita SQLite para
     funcionar en el navegador (igual que en Peliculeitor).
4. En `android/app/src/main/AndroidManifest.xml`:
   - Cambia `android:label="saldado"` por `android:label="Saldado"`.
   - Dentro de `<queries>` añade esto, para poder abrir WhatsApp en Android 11+:
     ```xml
     <intent>
         <action android:name="android.intent.action.VIEW" />
         <data android:scheme="https" />
     </intent>
     ```
5. Comprueba y ejecuta:
   ```
   flutter analyze
   flutter test
   flutter run -d chrome
   ```

## Estructura

```
lib/
  main.dart                   Arranque y tema
  tema.dart                   Colores y estilos (los del logo)
  models/modelos.dart         Grupo, Miembro, Gasto, Parte, Pago, Moneda, Categoria
  logica/cuentas.dart         Reparto, saldos, liquidación y formato de importes
  logica/textos.dart          Fechas y texto del resumen para compartir
  data/base_datos.dart        SQLite: tablas y consultas
  screens/
    grupos_screen.dart        Lista de grupos
    editar_grupo_screen.dart  Crear / editar grupo y personas
    grupo_screen.dart         Gastos y Saldos de un grupo
    editar_gasto_screen.dart  Añadir / editar gasto y su reparto
  widgets/comunes.dart        Avatar, icono de categoría, saldo, logo…
test/                         Tests de la lógica y de algunos widgets
assets/icon/                  Logo en SVG y PNG para iconos y arranque
store/                        Icono 512 y gráfico 1024×500 para Google Play
```

## Decisiones de diseño (útiles para explicar en clase)

- **Importes en céntimos enteros.** `12,50 €` se guarda como `1250`. Con
  `double`, `0.1 + 0.2` no da `0.3` y al repartir se pierden céntimos.
- **Reparto sin perder céntimos.** 10,00 € entre 3 → 3,34 + 3,33 + 3,33: los
  céntimos que sobran se dan de uno en uno (`repartirIgual`).
- **Saldo de cada persona** = lo que pagó − lo que le correspondía ± pagos
  hechos o recibidos. La suma de todos los saldos es siempre 0.
- **Liquidación voraz.** Quien más debe paga a quien más le deben; con n
  personas salen como mucho n − 1 transferencias (`liquidar`).
- **La lógica no depende de Flutter** (`lib/logica/`), así que se prueba con
  tests unitarios rápidos: `flutter test`.
- **Base de datos** con claves foráneas y `ON DELETE CASCADE`: al borrar un
  grupo desaparecen sus personas, gastos y pagos. Guardar un gasto con sus
  partes se hace en una **transacción**.
- No se puede quitar del grupo a alguien que ya aparece en gastos o pagos.

## Logo

Una moneda partida en dos mitades: repartir y quedar a la par. Original en
`assets/icon/logo_saldado.svg`. Colores: verde `#0E9F7E` → `#0B7A62` y menta
`#9BF2D3`.
