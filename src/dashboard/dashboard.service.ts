import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection } from '@nestjs/typeorm';
import { Connection } from 'typeorm';
import { DashboardResponseDto, ResumenMensualDto, GastoCategoriaDto, IngresoCategoriaDto, EvolucionMensualDto, PresupuestoDashboardDto, MetaDashboardDto } from './dto/dashboard-response.dto';

@Injectable()
export class DashboardService {
  private readonly logger = new Logger(DashboardService.name);

  constructor(
    @InjectConnection()
    private readonly connection: Connection,
  ) {}

  async getDashboard(usuarioId: number, fecha?: string): Promise<DashboardResponseDto> {
    const date = fecha ? new Date(fecha + '-01') : new Date();
    const year = date.getFullYear();
    const month = date.getMonth() + 1;

    const mesActual = `${year}-${String(month).padStart(2, '0')}`;
    const mesAnterior = month === 1
      ? `${year - 1}-12`
      : `${year}-${String(month - 1).padStart(2, '0')}`;

    const resumen = await this.getResumenMensual(usuarioId, mesActual, mesAnterior);
    const gastosPorCategoria = await this.getGastosPorCategoria(usuarioId, mesActual);
    const ingresosPorCategoria = await this.getIngresosPorCategoria(usuarioId, mesActual);
    const evolucion = await this.getEvolucionMensual(usuarioId, 12, mesActual);
    const presupuestos = await this.getPresupuestosDashboard(usuarioId, mesActual);
    const metas = await this.getMetasDashboard(usuarioId);

    return {
      resumen_mensual: resumen,
      gastos_por_categoria: gastosPorCategoria,
      ingresos_por_categoria: ingresosPorCategoria,
      evolucion_mensual: evolucion,
      presupuestos,
      metas,
    };
  }

  private async getResumenMensual(
    usuarioId: number,
    mesActual: string,
    mesAnterior: string,
  ): Promise<ResumenMensualDto> {
    const query = `
      DECLARE @TipoIngresoId BIGINT, @TipoGastoId BIGINT;
      SELECT @TipoIngresoId = id FROM tipos_transaccion WHERE nombre = 'INGRESO';
      SELECT @TipoGastoId = id FROM tipos_transaccion WHERE nombre = 'GASTO';

      SELECT
        ISNULL(SUM(CASE WHEN t.tipo_transaccion_id = @TipoIngresoId THEN t.monto ELSE 0 END), 0) AS ingresos,
        ISNULL(SUM(CASE WHEN t.tipo_transaccion_id = @TipoGastoId THEN t.monto ELSE 0 END), 0) AS gastos,
        ISNULL(SUM(CASE WHEN t.tipo_transaccion_id = @TipoIngresoId THEN t.monto ELSE 0 END), 0)
        - ISNULL(SUM(CASE WHEN t.tipo_transaccion_id = @TipoGastoId THEN t.monto ELSE 0 END), 0) AS balance
      FROM transacciones t
      WHERE t.usuario_id = @0
        AND t.activa = 1
        AND FORMAT(t.fecha_transaccion, 'yyyy-MM') = @1
    `;

    const res = await this.connection.manager.query(query, [usuarioId, mesActual]);
    const current = res[0];

    const prevRes = await this.connection.manager.query(query, [usuarioId, mesAnterior]);
    const prev = prevRes[0];

    return {
      ingresos: parseFloat(current.ingresos) || 0,
      gastos: parseFloat(current.gastos) || 0,
      balance: parseFloat(current.balance) || 0,
      ingresos_mes_anterior: parseFloat(prev.ingresos) || 0,
      gastos_mes_anterior: parseFloat(prev.gastos) || 0,
      balance_mes_anterior: parseFloat(prev.balance) || 0,
      variacion_ingresos: this.calcVariacion(current.ingresos, prev.ingresos),
      variacion_gastos: this.calcVariacion(current.gastos, prev.gastos),
    };
  }

  private async getGastosPorCategoria(
    usuarioId: number,
    mes: string,
  ): Promise<GastoCategoriaDto[]> {
    const query = `
      DECLARE @TipoGastoId BIGINT;
      SELECT @TipoGastoId = id FROM tipos_transaccion WHERE nombre = 'GASTO';

      SELECT
        c.id AS categoria_id,
        c.nombre,
        c.color,
        c.icono,
        ISNULL(SUM(t.monto), 0) AS total,
        COUNT(t.id) AS transacciones
      FROM categorias c
      INNER JOIN transacciones t ON t.categoria_id = c.id
        AND t.usuario_id = @0
        AND t.tipo_transaccion_id = @TipoGastoId
        AND t.activa = 1
        AND FORMAT(t.fecha_transaccion, 'yyyy-MM') = @1
      WHERE (c.usuario_id = @0 OR c.usuario_id IS NULL) AND c.activo = 1
      GROUP BY c.id, c.nombre, c.color, c.icono
      ORDER BY total DESC
    `;

    const rows = await this.connection.manager.query(query, [usuarioId, mes]);
    const totalGastos = rows.reduce((s: number, r: any) => s + (parseFloat(r.total) || 0), 0);

    return rows.map((r: any) => ({
      categoria_id: parseInt(r.categoria_id),
      nombre: r.nombre,
      color: r.color,
      icono: r.icono,
      total: parseFloat(r.total) || 0,
      porcentaje: totalGastos > 0 ? Math.round((parseFloat(r.total) / totalGastos) * 100) : 0,
      transacciones: parseInt(r.transacciones) || 0,
    }));
  }

  private async getIngresosPorCategoria(
    usuarioId: number,
    mes: string,
  ): Promise<IngresoCategoriaDto[]> {
    const query = `
      DECLARE @TipoIngresoId BIGINT;
      SELECT @TipoIngresoId = id FROM tipos_transaccion WHERE nombre = 'INGRESO';

      SELECT
        c.id AS categoria_id,
        c.nombre,
        c.color,
        c.icono,
        ISNULL(SUM(t.monto), 0) AS total,
        COUNT(t.id) AS transacciones
      FROM categorias c
      INNER JOIN transacciones t ON t.categoria_id = c.id
        AND t.usuario_id = @0
        AND t.tipo_transaccion_id = @TipoIngresoId
        AND t.activa = 1
        AND FORMAT(t.fecha_transaccion, 'yyyy-MM') = @1
      WHERE (c.usuario_id = @0 OR c.usuario_id IS NULL) AND c.activo = 1
      GROUP BY c.id, c.nombre, c.color, c.icono
      ORDER BY total DESC
    `;

    const rows = await this.connection.manager.query(query, [usuarioId, mes]);
    const totalIngresos = rows.reduce((s: number, r: any) => s + (parseFloat(r.total) || 0), 0);

    return rows.map((r: any) => ({
      categoria_id: parseInt(r.categoria_id),
      nombre: r.nombre,
      color: r.color,
      icono: r.icono,
      total: parseFloat(r.total) || 0,
      porcentaje: totalIngresos > 0 ? Math.round((parseFloat(r.total) / totalIngresos) * 100) : 0,
      transacciones: parseInt(r.transacciones) || 0,
    }));
  }

  private async getEvolucionMensual(
    usuarioId: number,
    meses: number,
    hastaMes: string,
  ): Promise<EvolucionMensualDto[]> {
    const query = `
      DECLARE @TipoIngresoId BIGINT, @TipoGastoId BIGINT;
      SELECT @TipoIngresoId = id FROM tipos_transaccion WHERE nombre = 'INGRESO';
      SELECT @TipoGastoId = id FROM tipos_transaccion WHERE nombre = 'GASTO';

      SELECT
        FORMAT(t.fecha_transaccion, 'yyyy-MM') AS mes,
        ISNULL(SUM(CASE WHEN t.tipo_transaccion_id = @TipoIngresoId THEN t.monto ELSE 0 END), 0) AS ingresos,
        ISNULL(SUM(CASE WHEN t.tipo_transaccion_id = @TipoGastoId THEN t.monto ELSE 0 END), 0) AS gastos
      FROM transacciones t
      WHERE t.usuario_id = @0
        AND t.activa = 1
        AND t.fecha_transaccion >= DATEADD(MONTH, -(@1 - 1), DATEFROMPARTS(LEFT(@2, 4), RIGHT(@2, 2), 1))
        AND t.fecha_transaccion < DATEADD(MONTH, 1, DATEFROMPARTS(LEFT(@2, 4), RIGHT(@2, 2), 1))
      GROUP BY FORMAT(t.fecha_transaccion, 'yyyy-MM')
      ORDER BY mes
    `;

    const rows = await this.connection.manager.query(query, [usuarioId, meses, hastaMes]);

    return rows.map((r: any) => ({
      mes: r.mes,
      ingresos: parseFloat(r.ingresos) || 0,
      gastos: parseFloat(r.gastos) || 0,
    }));
  }

  private async getPresupuestosDashboard(
    usuarioId: number,
    mes: string,
  ): Promise<PresupuestoDashboardDto[]> {
    const query = `
      SELECT
        p.id,
        p.nombre,
        p.monto_limite,
        p.monto_gastado,
        c.nombre AS categoria_nombre,
        c.color AS categoria_color,
        c.icono AS categoria_icono,
        p.periodo,
        p.fecha_fin,
        CASE
          WHEN p.monto_limite > 0 THEN ROUND((p.monto_gastado / p.monto_limite) * 100, 1)
          ELSE 0
        END AS porcentaje
      FROM dbo.presupuestos p
      LEFT JOIN dbo.categorias c ON p.categoria_id = c.id
      WHERE p.usuario_id = @0
        AND p.activo = 1
        AND FORMAT(p.fecha_inicio, 'yyyy-MM') <= @1
        AND FORMAT(p.fecha_fin, 'yyyy-MM') >= @1
      ORDER BY porcentaje DESC
    `;

    const rows = await this.connection.manager.query(query, [usuarioId, mes]);

    return rows.map((r: any) => ({
      id: parseInt(r.id),
      nombre: r.nombre,
      monto_limite: parseFloat(r.monto_limite) || 0,
      monto_gastado: parseFloat(r.monto_gastado) || 0,
      porcentaje: parseFloat(r.porcentaje) || 0,
      periodo: r.periodo,
      categoria_nombre: r.categoria_nombre,
      categoria_color: r.categoria_color,
      categoria_icono: r.categoria_icono,
      dias_restantes: r.fecha_fin
        ? Math.max(0, Math.ceil((new Date(r.fecha_fin).getTime() - Date.now()) / 86400000))
        : 0,
    }));
  }

  private async getMetasDashboard(usuarioId: number): Promise<MetaDashboardDto[]> {
    const query = `
      SELECT
        m.id,
        m.nombre,
        m.monto_actual,
        m.monto_objetivo,
        m.color,
        m.icono,
        CASE
          WHEN m.monto_objetivo > 0 THEN ROUND((m.monto_actual / m.monto_objetivo) * 100, 1)
          ELSE 0
        END AS porcentaje
      FROM dbo.metas m
      WHERE m.usuario_id = @0
        AND m.activa = 1
      ORDER BY porcentaje DESC
    `;

    const rows = await this.connection.manager.query(query, [usuarioId]);

    return rows.map((r: any) => ({
      id: parseInt(r.id),
      nombre: r.nombre,
      monto_actual: parseFloat(r.monto_actual) || 0,
      monto_objetivo: parseFloat(r.monto_objetivo) || 0,
      porcentaje: parseFloat(r.porcentaje) || 0,
      color: r.color,
      icono: r.icono,
    }));
  }

  private calcVariacion(current: string | number, previous: string | number): number {
    const cur = parseFloat(String(current)) || 0;
    const prev = parseFloat(String(previous)) || 0;
    if (prev === 0) return cur > 0 ? 100 : 0;
    return Math.round(((cur - prev) / prev) * 100);
  }
}
