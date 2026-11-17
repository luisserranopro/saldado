import 'dart:ui';

/// Idioma de la app: español si el dispositivo está en español; inglés en
/// cualquier otro caso. Los tests pueden fijarlo con [Idioma.forzar].
class Idioma {
  static String? _forzado;

  /// Solo para tests: Idioma.forzar('es') o Idioma.forzar('en'); null = el del sistema.
  static void forzar(String? codigo) => _forzado = codigo;

  static String get codigo => _forzado ?? PlatformDispatcher.instance.locale.languageCode;
  static bool get es => codigo == 'es';
}

/// Todos los textos de la interfaz en español e inglés.
class Tx {
  static String _t(String es, String en) => Idioma.es ? es : en;

  // ---------------------------------------------------------------- General
  static String get cancelar => _t('Cancelar', 'Cancel');
  static String get borrar => _t('Borrar', 'Delete');
  static String get deshacer => _t('Deshacer', 'Undo');
  static String get hoy => _t('Hoy', 'Today');
  static String get ayer => _t('Ayer', 'Yesterday');

  // ---------------------------------------------------------------- Grupos
  static String get nuevoGrupo => _t('Nuevo grupo', 'New group');
  static String get acercaDe => _t('Acerca de Saldado', 'About Saldado');
  static String get bienvenidaTitulo =>
      _t('Cuentas claras, amistad larga', 'Settle up, stay friends');
  static String get bienvenidaTexto => _t(
      'Crea un grupo para un viaje, el piso compartido o una cena, '
          'apunta quién paga cada cosa y Saldado te dice quién debe a quién.',
      'Create a group for a trip, a shared flat or a dinner, '
          'record who pays for what and Saldado tells you who owes whom.');
  static String get crearPrimerGrupo => _t('Crear mi primer grupo', 'Create my first group');
  static String personas(int n) => Idioma.es
      ? (n == 1 ? '1 persona' : '$n personas')
      : (n == 1 ? '1 person' : '$n people');
  static String get gastado => _t('gastado', 'spent');

  // ---------------------------------------------------------------- Editar grupo
  static String get editarGrupo => _t('Editar grupo', 'Edit group');
  static String get nombreGrupo => _t('Nombre del grupo', 'Group name');
  static String get nombreGrupoEjemplo =>
      _t('Viaje a Lisboa, Piso, Cena de Navidad…', 'Lisbon trip, Flat, Christmas dinner…');
  static String get ponleNombre => _t('Ponle un nombre', 'Give it a name');
  static String get moneda => _t('Moneda', 'Currency');
  static String get tituloPersonas => _t('Personas', 'People');
  static String get explicacionPersonas =>
      _t('Quién comparte los gastos de este grupo.', 'Who shares the costs in this group.');
  static String persona(int n) => _t('Persona $n', 'Person $n');
  static String get quitar => _t('Quitar', 'Remove');
  static String get anadirPersona => _t('Añadir persona', 'Add person');
  static String get guardarCambios => _t('Guardar cambios', 'Save changes');
  static String get crearGrupo => _t('Crear grupo', 'Create group');
  static String get minimoDos => _t('Añade al menos dos personas.', 'Add at least two people.');
  static String get nombreRepetido =>
      _t('Hay dos personas con el mismo nombre.', 'Two people have the same name.');
  static String get escribeNombreOQuita =>
      _t('Escribe un nombre o quita a la persona', 'Enter a name or remove this person');
  static String noSePuedeQuitar(String nombre) => _t(
      '$nombre tiene gastos o pagos; no se puede quitar del grupo.',
      '$nombre has expenses or payments and can’t be removed from the group.');
  static String get errorGuardarGrupo =>
      _t('No se ha podido guardar el grupo.', 'The group could not be saved.');

  // ---------------------------------------------------------------- Grupo
  static String get compartirResumen => _t('Compartir resumen', 'Share summary');
  static String get masOpciones => _t('Más opciones', 'More options');
  static String get editarGrupoYPersonas =>
      _t('Editar grupo y personas', 'Edit group and people');
  static String get borrarGrupo => _t('Borrar grupo', 'Delete group');
  static String borrarGrupoTitulo(String nombre) =>
      _t('¿Borrar «$nombre»?', 'Delete “$nombre”?');
  static String get borrarGrupoTexto => _t(
      'Se borrarán todos sus gastos y pagos. No se puede deshacer.',
      'All its expenses and payments will be deleted. This can’t be undone.');
  static String get pestanaGastos => _t('Gastos', 'Expenses');
  static String get pestanaSaldos => _t('Saldos', 'Balances');
  static String get anadirGasto => _t('Añadir gasto', 'Add expense');
  static String get enviarWhatsApp => _t('Enviar por WhatsApp', 'Send via WhatsApp');
  static String get copiarResumen => _t('Copiar resumen', 'Copy summary');
  static String get copiarResumenDetalle =>
      _t('Para pegarlo en cualquier otra app', 'To paste it into any other app');
  static String get resumenCopiado => _t('Resumen copiado', 'Summary copied');

  static String get sinGastosTitulo => _t('Todavía no hay gastos', 'No expenses yet');
  static String get sinGastosTexto => _t(
      'Pulsa «Añadir gasto» para apuntar el primero: qué es, cuánto costó, '
          'quién lo pagó y entre quiénes se reparte.',
      'Tap “Add expense” to record the first one: what it was, how much it cost, '
          'who paid and who shares it.');
  static String get totalGastado => _t('Total gastado', 'Total spent');
  static String numGastos(int n) => Idioma.es
      ? (n == 1 ? '1 gasto' : '$n gastos')
      : (n == 1 ? '1 expense' : '$n expenses');
  static String pagoYReparto(String nombre, bool todos, int n) => Idioma.es
      ? 'Pagó $nombre · ${todos ? 'entre todos' : 'entre $n'}'
      : 'Paid by $nombre · ${todos ? 'split between everyone' : 'split between $n'}';
  static String pagoA(String de, String a) => _t('$de pagó a $a', '$de paid $a');
  static String get pagoParaSaldar => _t('Pago para saldar', 'Settle-up payment');
  static String get borrarPagoTitulo => _t('¿Borrar este pago?', 'Delete this payment?');
  static String get borrarPagoTexto => _t(
      'Las deudas volverán a aparecer en Saldos.',
      'The debts will show up again in Balances.');

  static String get comoSaldar => _t('Cómo saldar las cuentas', 'How to settle up');
  static String get sinGastosSaldos => _t(
      'Cuando apuntéis gastos, aquí verás quién debe a quién.',
      'Once you add expenses, you’ll see who owes whom here.');
  static String get todoSaldado =>
      _t('¡Todo saldado! Nadie debe nada a nadie.', 'All settled! Nobody owes anything.');
  static String conPagos(int n) => Idioma.es
      ? (n == 1 ? 'Con un solo pago quedáis en paz:' : 'Con estos $n pagos quedáis en paz:')
      : (n == 1 ? 'One payment settles everything:' : 'These $n payments settle everything:');
  static String pagaA(String de, String a) => _t('$de paga a $a', '$de pays $a');
  static String get marcarPagado => _t('Marcar como pagado', 'Mark as paid');
  static String pagoRegistrado(String de, String a) =>
      _t('Pago registrado: $de → $a', 'Payment recorded: $de → $a');
  static String get saldoPersona => _t('Saldo de cada persona', 'Balance per person');
  static String pagoYParte(String pagado, String parte) =>
      _t('Pagó $pagado · Su parte $parte', 'Paid $pagado · Their share $parte');
  static String get leDeben => _t('le deben', 'is owed');
  static String get debe => _t('debe', 'owes');
  static String get enPaz => _t('en paz', 'settled');

  // ---------------------------------------------------------------- Editar gasto
  static String get nuevoGasto => _t('Nuevo gasto', 'New expense');
  static String get editarGasto => _t('Editar gasto', 'Edit expense');
  static String get borrarGasto => _t('Borrar gasto', 'Delete expense');
  static String get borrarGastoTitulo => _t('¿Borrar este gasto?', 'Delete this expense?');
  static String borrarGastoTexto(String concepto) => _t(
      '«$concepto» desaparecerá de las cuentas del grupo.',
      '“$concepto” will be removed from the group’s balances.');
  static String get concepto => _t('Concepto', 'Description');
  static String get conceptoEjemplo =>
      _t('Cena, gasolina, entradas…', 'Dinner, fuel, tickets…');
  static String get escribeQueEs => _t('Escribe qué es', 'Enter a description');
  static String get importe => _t('Importe', 'Amount');
  static String get importeEjemplo => _t('0,00', '0.00');
  static String get importeNoValido =>
      _t('Escribe un importe, por ejemplo 12,50', 'Enter an amount, e.g. 12.50');
  static String get importeCero =>
      _t('El importe tiene que ser mayor que 0', 'The amount must be greater than 0');
  static String get pagadoPor => _t('Pagado por', 'Paid by');
  static String get categoria => _t('Categoría', 'Category');
  static String get comoSeReparte => _t('¿Cómo se reparte?', 'How is it split?');
  static String get partesIguales => _t('A partes iguales', 'Equally');
  static String get importesExactos => _t('Importes exactos', 'Exact amounts');
  static String get noParticipa => _t('No participa', 'Not included');
  static String get eligeAlguien => _t(
      'Elige al menos una persona para repartir el gasto.',
      'Choose at least one person to split the expense with.');
  static String revisaImporte(String nombre) =>
      _t('Revisa el importe de $nombre.', 'Check the amount for $nombre.');
  static String debenSumar(String total) => _t(
      'Los importes de cada persona deben sumar $total.',
      'The amounts per person must add up to $total.');
  static String cuadra(String total) => _t('Cuadra: $total', 'Adds up: $total');
  static String faltan(String cantidad) =>
      _t('Faltan $cantidad por asignar', '$cantidad left to assign');
  static String sobran(String cantidad) => _t('Sobran $cantidad', 'Over by $cantidad');
  static String get errorGuardarGasto =>
      _t('No se ha podido guardar el gasto.', 'The expense could not be saved.');

  // ---------------------------------------------------------------- Acerca de
  static String get lema => _t('Gastos compartidos, cuentas claras.', 'Shared costs, clear accounts.');
  static String get textoAcercaDe => _t(
      'Tus grupos y gastos se guardan solo en este dispositivo: '
          'sin registro, sin publicidad y sin seguimiento.',
      'Your groups and expenses are stored only on this device: '
          'no sign-up, no ads and no tracking.');
  static String get politicaPrivacidad => _t('Política de privacidad', 'Privacy policy');

  // ---------------------------------------------------------------- Resumen compartido
  static String get resumenTotal => _t('Total gastado', 'Total spent');
  static String get resumenSaldos => _t('Saldos', 'Balances');
  static String get resumenTodoSaldado => _t('¡Todo saldado!', 'All settled!');
  static String get resumenParaSaldar => _t('Para saldar las cuentas', 'To settle up');
  static String get resumenFirma => _t('Hecho con Saldado', 'Made with Saldado');
}
