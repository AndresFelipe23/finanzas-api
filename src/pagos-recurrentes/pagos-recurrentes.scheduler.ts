import { Injectable, Logger, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { InjectConnection } from '@nestjs/typeorm';
import { Connection } from 'typeorm';

type Frecuencia = 'DIARIO' | 'SEMANAL' | 'MENSUAL' | 'BIMESTRAL' | 'TRIMESTRAL' | 'SEMESTRAL' | 'ANUAL';

@Injectable()
export class PagosRecurrentesScheduler implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(PagosRecurrentesScheduler.name);
  private timer?: ReturnType<typeof setInterval>;

  constructor(
    @InjectConnection()
    private readonly connection: Connection,
  ) {}

  onModuleInit() {
    // Ejecuta cada 15 minutos
    this.timer = setInterval(() => this.run(), 15 * 60 * 1000);
    // Primera ejecución al iniciar
    this.run().catch((e) => this.logger.error(e.message));
  }

  onModuleDestroy() {
    if (this.timer) clearInterval(this.timer);
  }

  private async run() {
    try {
      const hoy = new Date();
      const start = new Date(hoy.getFullYear(), hoy.getMonth(), hoy.getDate(), 0, 0, 0);
      const end = new Date(hoy.getFullYear(), hoy.getMonth(), hoy.getDate(), 23, 59, 59);

      // Obtener reglas activas
      const reglas: any[] = await this.connection.manager.query(
        `SELECT * FROM pagos_recurrentes WHERE activo = 1`,
      );

      for (const r of reglas) {
        if (!this.estaEnVentana(r, hoy)) continue;
        if (!this.correspondeHoy(r, hoy)) continue;

        // Evitar duplicados: ¿ya existe transacción hoy para esta regla?
        const dup = await this.connection.manager.query(
          `SELECT TOP 1 1 FROM transacciones
           WHERE usuario_id=@0
             AND ISNULL(cuenta_id, -1) = ISNULL(@1, -1)
             AND ISNULL(categoria_id, -1) = ISNULL(@2, -1)
             AND monto = @3
             AND repetir = 1
             AND fecha_transaccion >= @4 AND fecha_transaccion <= @5`,
          [
            r.usuario_id,
            r.cuenta_id,
            r.categoria_id,
            r.monto,
            start,
            end,
          ],
        );
        if (dup && dup.length > 0) continue;

        // Ejecutar ahora usando SP existente
        await this.connection.manager.query(
          `EXEC sp_pago_recurrente_execute_now @Id=@0,@UsuarioId=@1,@FechaEjecucion=@2`,
          [r.id, r.usuario_id, hoy],
        );
        this.logger.log(`Pago recurrente ejecutado: id=${r.id} usuario=${r.usuario_id}`);
      }
    } catch (error) {
      this.logger.error(`Error en scheduler: ${error.message}`);
    }
  }

  private estaEnVentana(r: any, fecha: Date): boolean {
    const fi = new Date(r.fecha_inicio);
    const ff = r.fecha_fin ? new Date(r.fecha_fin) : undefined;
    if (fecha < new Date(fi.getFullYear(), fi.getMonth(), fi.getDate())) return false;
    if (ff && fecha > new Date(ff.getFullYear(), ff.getMonth(), ff.getDate(), 23, 59, 59)) return false;
    return true;
  }

  private correspondeHoy(r: any, hoy: Date): boolean {
    const frecuencia: Frecuencia = r.frecuencia as Frecuencia;
    switch (frecuencia) {
      case 'DIARIO':
        return true;
      case 'SEMANAL': {
        // SQL: 1=Lunes..7=Domingo; JS: 0=Domingo..6=Sabado
        const jsDay = hoy.getDay();
        const sqlDay = jsDay === 0 ? 7 : jsDay; // 1..7
        return sqlDay === (r.dia_semana || 1);
      }
      case 'MENSUAL':
      case 'BIMESTRAL':
      case 'TRIMESTRAL':
      case 'SEMESTRAL':
      case 'ANUAL': {
        const step = this.mesesPaso(frecuencia);
        const dia = r.dia_vencimiento || 1;
        // Tomar el mes vigente desde fecha_inicio
        const base = new Date(r.fecha_inicio);
        // Avanzar en múltiplos de step hasta alcanzar o pasar el mes actual
        const cand = new Date(base.getFullYear(), base.getMonth(), 1);
        while (cand <= hoy) {
          const ejec = new Date(cand.getFullYear(), cand.getMonth(), this.ajustarDiaMes(cand.getFullYear(), cand.getMonth(), dia));
          if (this.sameDate(ejec, hoy)) return true;
          cand.setMonth(cand.getMonth() + step);
        }
        return false;
      }
      default:
        return false;
    }
  }

  private mesesPaso(freq: Frecuencia): number {
    switch (freq) {
      case 'MENSUAL': return 1;
      case 'BIMESTRAL': return 2;
      case 'TRIMESTRAL': return 3;
      case 'SEMESTRAL': return 6;
      case 'ANUAL': return 12;
      default: return 1;
    }
  }

  private ajustarDiaMes(year: number, month: number, dia: number): number {
    // Último día del mes
    const ultimo = new Date(year, month + 1, 0).getDate();
    return Math.min(dia, ultimo);
  }

  private sameDate(a: Date, b: Date): boolean {
    return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();
  }
}


