/**
 * Fechas en hora de Colombia (UTC-5, sin horario de verano).
 *
 * Convención de la API: la base de datos guarda la hora de Colombia como
 * fecha "sin zona" (los SP usan DATEADD(HOUR, -5, GETUTCDATE())), y el driver
 * mssql envía y lee los `Date` por sus campos UTC. Por eso un `Date` que va a
 * la BD debe llevar la hora de Colombia en sus campos UTC, y el proceso corre
 * en UTC (main.ts) para que los getters locales coincidan con esos campos,
 * igual en un servidor propio que en Vercel.
 */
const OFFSET_COLOMBIA_MS = 5 * 60 * 60 * 1000;

/** "Ahora" en Colombia, listo para enviar a la BD o leer con getters UTC. */
export function ahoraColombia(): Date {
  return new Date(Date.now() - OFFSET_COLOMBIA_MS);
}

/** Hoy en Colombia como 'YYYY-MM-DD'. */
export function hoyColombia(): string {
  return ahoraColombia().toISOString().slice(0, 10);
}

/**
 * Fecha para los SP de transacciones (@FechaTransaccion + @UsarHora) a partir
 * de lo que envía la app:
 * - fecha y hora local sin zona ('2026-07-25T21:40:12'): es la hora del
 *   teléfono del usuario, en su país; se guarda tal cual (usarHora);
 * - solo fecha, o medianoche exacta (versiones viejas de la app mandaban
 *   'T00:00:00'): vale la fecha y el SP le pone la hora de Colombia;
 * - instante con zona: día de Colombia;
 * - vacío: null, el SP usa la fecha y hora de Colombia.
 */
export function fechaDelCliente(
  entrada?: string | null,
): { valor: string | null; usarHora: boolean } {
  const texto = typeof entrada === 'string' ? entrada.trim() : '';
  if (!texto) return { valor: null, usarHora: false };
  const local = texto.match(
    /^(\d{4}-\d{2}-\d{2})[T\s](\d{2}):(\d{2})(?::(\d{2}))?(?:\.\d+)?$/,
  );
  if (local) {
    const [, dia, hh, mm, ss = '00'] = local;
    if (hh === '00' && mm === '00' && ss === '00') {
      return { valor: dia, usarHora: false };
    }
    return { valor: `${dia}T${hh}:${mm}:${ss}`, usarHora: true };
  }
  return { valor: diaColombia(texto), usarHora: false };
}

/**
 * Día de Colombia ('YYYY-MM-DD') a partir de lo que envía el cliente:
 * - fecha u hora local sin zona ('2026-07-25', '2026-07-25T12:00:00'): su
 *   parte de fecha ya es la que el usuario quiere;
 * - instante con Z u offset: se convierte a hora de Colombia;
 * - vacío o inválido: hoy en Colombia.
 *
 * Se pasa a los SP como texto (no como Date) para que el driver no la
 * desplace de día; los SP le añaden la hora actual de Colombia.
 */
export function diaColombia(entrada?: string | Date | null): string {
  if (entrada instanceof Date) {
    return isNaN(entrada.getTime())
      ? hoyColombia()
      : new Date(entrada.getTime() - OFFSET_COLOMBIA_MS).toISOString().slice(0, 10);
  }
  const texto = typeof entrada === 'string' ? entrada.trim() : '';
  if (!texto) return hoyColombia();
  const sinZona = texto.match(
    /^(\d{4}-\d{2}-\d{2})(?:[T\s]\d{2}:\d{2}(?::\d{2})?(?:\.\d+)?)?$/,
  );
  if (sinZona) return sinZona[1];
  const instante = new Date(texto);
  return isNaN(instante.getTime())
    ? hoyColombia()
    : new Date(instante.getTime() - OFFSET_COLOMBIA_MS).toISOString().slice(0, 10);
}
