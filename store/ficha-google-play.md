# Material para Google Play Console · Saldado

Revisa los corchetes `[...]` antes de usarlos.

## Imágenes (en esta carpeta)

| Archivo | Dónde va |
|---|---|
| `icono-512.png` | Ficha de Play Store → Icono de la aplicación (512×512) |
| `imagen-destacada-1024x500.png` | Ficha de Play Store → Gráfico de funciones (1024×500) |

**Capturas de pantalla** (mínimo 2, de teléfono). Hazlas con la app
funcionando en el emulador (botón de cámara de la barra lateral). Antes, crea
un grupo de ejemplo con nombres inventados, por ejemplo «Viaje a Lisboa» con
Ana, Luis, Eva y Marcos, y 5 o 6 gastos de distintas categorías. Capturas
recomendadas:
1. Lista de grupos.
2. Pestaña Gastos del grupo, con el total arriba.
3. Pestaña Saldos con «Cómo saldar las cuentas».
4. Formulario de nuevo gasto con el reparto a partes iguales.

## Ficha en español (es-ES)

**Nombre de la app** (máx. 30)
```
Saldado: gastos compartidos
```
(Si prefieres solo la marca: `Saldado`.)

**Descripción breve** (máx. 80)
```
Apunta los gastos del grupo y salda cuentas con el menor número de pagos.
```

**Descripción completa**
```
Saldado te ayuda a llevar las cuentas de un viaje, del piso compartido o de una cena con amigos, sin discusiones.

• Crea un grupo y añade a las personas que comparten los gastos.
• Apunta cada gasto: qué es, cuánto costó, quién lo pagó y la fecha.
• Repártelo a partes iguales entre quien quieras o con importes exactos.
• Mira el saldo de cada persona: quién ha pagado de más y quién debe.
• Saldado calcula el mínimo de pagos para que todos quedéis en paz.
• Marca los pagos cuando se hagan y comparte el resumen por WhatsApp.

Cuentas exactas al céntimo: si 10 € se reparten entre 3, nadie pierde ni gana un céntimo.

Varias monedas: euro, dólar, libra, peso mexicano y franco suizo.

Sin registro, sin publicidad y sin conexión: tus datos se guardan solo en tu móvil.

Disponible en español e inglés.

Cuentas claras, amistad larga.
```

## Listing in English (en-US)

**App name** (max. 30)
```
Saldado: Split shared costs
```

**Short description** (max. 80)
```
Track group expenses and settle up with the fewest payments.
```

**Full description**
```
Saldado keeps track of shared costs on a trip, in a shared flat or at a dinner with friends — no arguments.

• Create a group and add the people who share the costs.
• Add each expense: what it was, how much, who paid and when.
• Split it equally among whoever you choose, or by exact amounts.
• See everyone's balance: who has paid more and who owes.
• Saldado works out the fewest payments so everyone is square.
• Mark payments as done and share the summary on WhatsApp.

Accurate to the cent: split 10 € between 3 people and nobody gains or loses a cent.

Multiple currencies: euro, US dollar, pound sterling, Mexican peso and Swiss franc.

No sign-up, no ads, works offline: your data stays on your phone.

Available in English and Spanish.
```

## Datos de la ficha

- **Categoría:** Finanzas (o Herramientas).
- **Correo de contacto:** [CORREO DE CONTACTO] (obligatorio y público).
- **Política de privacidad (URL):**
  `https://github.com/luisserranopro/saldado/blob/main/docs/politica-privacidad.md`
  (si el repositorio se llama distinto, cambia también la constante
  `urlPrivacidad` de `lib/screens/acerca_de.dart`).

## Cuestionarios de «Contenido de la aplicación»

Respuestas que corresponden a la app tal como está programada. Confírmalas tú.

- **Acceso a la aplicación:** toda la funcionalidad está disponible sin
  restricciones (no hay inicio de sesión).
- **Anuncios:** no contiene anuncios.
- **Seguridad de los datos:**
  - ¿Recoge o comparte datos de usuario? **No.** Todo se guarda en el
    dispositivo y no se envía a ningún servidor. Compartir el resumen lo hace
    el propio usuario desde WhatsApp.
  - ¿Cifrado en tránsito? No aplica (no transmite datos).
- **Clasificación de contenido (IARC):** categoría *Utilidad, productividad,
  comunicación u otras*; sin violencia, sexo, lenguaje soez, drogas, juego,
  compras ni interacción entre usuarios.
- **Público objetivo:** mayores de 13 años (no dirigida a niños).
- **Aplicación financiera:** en la declaración de funciones financieras,
  indica que **no** ofrece servicios financieros (no hay préstamos, pagos
  reales, inversión ni criptomonedas): solo es un registro personal de gastos.
- **Aplicación de noticias / gubernamental / salud:** no.
