const _meses = [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic',
];

const _mesesLargos = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

const _diasSemana = [
  'lunes',
  'martes',
  'miércoles',
  'jueves',
  'viernes',
  'sábado',
  'domingo',
];

/// Formatea una fecha "YYYY-MM-DD" (la que devuelve el gateway) a "8 sep 2026".
/// Si no se puede parsear, devuelve el texto original tal cual.
String formatFechaCorta(String isoDate) {
  final fecha = DateTime.tryParse(isoDate);
  if (fecha == null) return isoDate;
  return '${fecha.day} ${_meses[fecha.month - 1]} ${fecha.year}';
}

/// Formatea un rango de fechas de forma compacta y legible:
/// mismo mes/año -> "8 - 13 sep 2026"; distinto mes -> "28 ago - 3 sep 2026";
/// distinto año -> fecha completa en ambos extremos.
/// Si alguna fecha no se puede parsear, cae al formato simple "corta - corta".
String formatRangoFechas(String desde, String hasta) {
  final inicio = DateTime.tryParse(desde);
  final fin = DateTime.tryParse(hasta);
  if (inicio == null || fin == null) {
    return '${formatFechaCorta(desde)} - ${formatFechaCorta(hasta)}';
  }

  if (inicio.year != fin.year) {
    return '${formatFechaCorta(desde)} - ${formatFechaCorta(hasta)}';
  }
  if (inicio.month != fin.month) {
    return '${inicio.day} ${_meses[inicio.month - 1]} - ${fin.day} ${_meses[fin.month - 1]} ${fin.year}';
  }
  return '${inicio.day} - ${fin.day} ${_meses[fin.month - 1]} ${fin.year}';
}

/// Fecha de hoy en formato largo, ej. "sábado, 12 de septiembre".
String formatFechaHoy() {
  final hoy = DateTime.now();
  return '${_diasSemana[hoy.weekday - 1]}, ${hoy.day} de ${_mesesLargos[hoy.month - 1]}';
}

/// Formatea un DateTime a "YYYY-MM-DD", el formato que espera el gateway.
String formatFechaIso(DateTime fecha) {
  final mes = fecha.month.toString().padLeft(2, '0');
  final dia = fecha.day.toString().padLeft(2, '0');
  return '${fecha.year}-$mes-$dia';
}

/// Formatea un DateTime a "DD/MM/AAAA" para mostrarlo en un formulario.
String formatFechaVisual(DateTime fecha) {
  final dia = fecha.day.toString().padLeft(2, '0');
  final mes = fecha.month.toString().padLeft(2, '0');
  return '$dia/$mes/${fecha.year}';
}

/// Una rutina se considera "activa" si su fecha_fin es hoy o posterior
/// (comparando solo la fecha, sin hora). Si fechaFinIso no se puede
/// parsear, se considera no activa.
bool esRutinaActiva(String fechaFinIso) {
  final fin = DateTime.tryParse(fechaFinIso);
  if (fin == null) return false;

  final hoy = DateTime.now();
  final hoySinHora = DateTime(hoy.year, hoy.month, hoy.day);
  final finSinHora = DateTime(fin.year, fin.month, fin.day);
  return !finSinHora.isBefore(hoySinHora);
}
