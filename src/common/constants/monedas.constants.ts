/**
 * Constantes de monedas de países de habla hispana
 * Códigos ISO 4217 de monedas soportadas por el sistema
 */

export class MonedasConstants {
  /**
   * Lista de códigos de monedas válidas (países de habla hispana)
   * Ordenadas alfabéticamente por código
   */
  static readonly MONEDAS_VALIDAS = [
    'ARS', // Peso Argentino
    'BOB', // Boliviano
    'CLP', // Peso Chileno
    'COP', // Peso Colombiano
    'CRC', // Colón (Costa Rica)
    'CUP', // Peso Cubano
    'DOP', // Peso Dominicano
    'EUR', // Euro (España)
    'GTQ', // Quetzal (Guatemala)
    'HNL', // Lempira (Honduras)
    'MXN', // Peso Mexicano
    'NIO', // Córdoba (Nicaragua)
    'PAB', // Balboa (Panamá)
    'PEN', // Sol Peruano
    'PYG', // Guaraní (Paraguay)
    'USD', // Dólar Estadounidense (Ecuador, El Salvador, Panamá)
    'UYU', // Peso Uruguayo
    'VES', // Bolívar Soberano (Venezuela)
  ] as const;

  /**
   * Moneda predeterminada del sistema
   */
  static readonly MONEDA_DEFAULT = 'COP';

  /**
   * Verifica si un código de moneda es válido
   * @param codigo Código de moneda a validar
   * @returns true si el código es válido, false en caso contrario
   */
  static esMonedaValida(codigo: string): boolean {
    return this.MONEDAS_VALIDAS.includes(codigo.toUpperCase() as any);
  }

  /**
   * Obtiene la lista de monedas válidas
   * @returns Array de códigos de monedas válidas
   */
  static getMonedasValidas(): readonly string[] {
    return this.MONEDAS_VALIDAS;
  }

  /**
   * Normaliza un código de moneda a mayúsculas
   * @param codigo Código de moneda
   * @returns Código normalizado o null si no es válido
   */
  static normalizarMoneda(codigo: string | undefined | null): string | null {
    if (!codigo) return null;
    const codigoUpper = codigo.toUpperCase();
    return this.esMonedaValida(codigoUpper) ? codigoUpper : null;
  }
}

