import { ApiProperty } from '@nestjs/swagger';

export class ResumenMensualDto {
  @ApiProperty() ingresos: number;
  @ApiProperty() gastos: number;
  @ApiProperty() balance: number;
  @ApiProperty({ required: false }) ingresos_mes_anterior?: number;
  @ApiProperty({ required: false }) gastos_mes_anterior?: number;
  @ApiProperty({ required: false }) balance_mes_anterior?: number;
  @ApiProperty({ required: false }) variacion_ingresos?: number;
  @ApiProperty({ required: false }) variacion_gastos?: number;
}

export class GastoCategoriaDto {
  @ApiProperty() categoria_id: number;
  @ApiProperty() nombre: string;
  @ApiProperty({ required: false }) color?: string;
  @ApiProperty({ required: false }) icono?: string;
  @ApiProperty() total: number;
  @ApiProperty() porcentaje: number;
  @ApiProperty() transacciones: number;
}

export class IngresoCategoriaDto {
  @ApiProperty() categoria_id: number;
  @ApiProperty() nombre: string;
  @ApiProperty({ required: false }) color?: string;
  @ApiProperty({ required: false }) icono?: string;
  @ApiProperty() total: number;
  @ApiProperty() porcentaje: number;
  @ApiProperty() transacciones: number;
}

export class EvolucionMensualDto {
  @ApiProperty() mes: string;
  @ApiProperty() ingresos: number;
  @ApiProperty() gastos: number;
}

export class PresupuestoDashboardDto {
  @ApiProperty() id: number;
  @ApiProperty() nombre: string;
  @ApiProperty() monto_limite: number;
  @ApiProperty() monto_gastado: number;
  @ApiProperty() porcentaje: number;
  @ApiProperty() periodo: string;
  @ApiProperty() categoria_nombre: string;
  @ApiProperty({ required: false }) categoria_color?: string;
  @ApiProperty({ required: false }) categoria_icono?: string;
  @ApiProperty() dias_restantes: number;
}

export class MetaDashboardDto {
  @ApiProperty() id: number;
  @ApiProperty() nombre: string;
  @ApiProperty() monto_actual: number;
  @ApiProperty() monto_objetivo: number;
  @ApiProperty() porcentaje: number;
  @ApiProperty({ required: false }) color?: string;
  @ApiProperty({ required: false }) icono?: string;
}

export class DashboardResponseDto {
  @ApiProperty() resumen_mensual: ResumenMensualDto;

  @ApiProperty({ type: [GastoCategoriaDto] })
  gastos_por_categoria: GastoCategoriaDto[];

  @ApiProperty({ type: [IngresoCategoriaDto] })
  ingresos_por_categoria: IngresoCategoriaDto[];

  @ApiProperty({ type: [EvolucionMensualDto] })
  evolucion_mensual: EvolucionMensualDto[];

  @ApiProperty({ type: [PresupuestoDashboardDto] })
  presupuestos: PresupuestoDashboardDto[];

  @ApiProperty({ type: [MetaDashboardDto] })
  metas: MetaDashboardDto[];
}
