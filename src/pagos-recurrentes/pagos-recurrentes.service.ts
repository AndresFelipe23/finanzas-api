import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { InjectConnection } from '@nestjs/typeorm';
import { Connection } from 'typeorm';
import { CreatePagoRecurrenteDto } from './dto/create-pago-recurrente.dto';
import { UpdatePagoRecurrenteDto } from './dto/update-pago-recurrente.dto';

@Injectable()
export class PagosRecurrentesService {
  private readonly logger = new Logger(PagosRecurrentesService.name);

  constructor(
    @InjectConnection()
    private readonly connection: Connection,
  ) {}

  async create(usuarioId: number, dto: CreatePagoRecurrenteDto) {
    const result = await this.connection.manager.query(
      `EXEC sp_pago_recurrente_create 
        @UsuarioId=@0,@CategoriaId=@1,@CuentaId=@2,@MetodoPagoId=@3,
        @Monto=@4,@Descripcion=@5,@Frecuencia=@6,@DiaVencimiento=@7,
        @DiaSemana=@8,@FechaInicio=@9,@FechaFin=@10`,
      [
        usuarioId,
        dto.categoriaId,
        dto.cuentaId ?? null,
        dto.metodoPagoId ?? null,
        dto.monto,
        dto.descripcion,
        dto.frecuencia,
        dto.diaVencimiento ?? null,
        dto.diaSemana ?? null,
        dto.fechaInicio,
        dto.fechaFin ?? null,
      ],
    );
    return result[0];
  }

  async findAll(usuarioId: number) {
    return await this.connection.manager.query(
      `EXEC sp_pago_recurrente_get_by_user @UsuarioId=@0`,
      [usuarioId],
    );
  }

  async findOne(usuarioId: number, id: number) {
    const result = await this.connection.manager.query(
      `EXEC sp_pago_recurrente_get_by_id @Id=@0,@UsuarioId=@1`,
      [id, usuarioId],
    );
    if (!result || result.length === 0) throw new NotFoundException('Pago recurrente no encontrado');
    return result[0];
  }

  async update(usuarioId: number, id: number, dto: UpdatePagoRecurrenteDto) {
    // PartialType hace que todas las propiedades sean opcionales, así que usamos 'in' para verificar
    const result = await this.connection.manager.query(
      `EXEC sp_pago_recurrente_update 
        @Id=@0,@UsuarioId=@1,@CategoriaId=@2,@CuentaId=@3,@MetodoPagoId=@4,
        @Monto=@5,@Descripcion=@6,@Frecuencia=@7,@DiaVencimiento=@8,
        @DiaSemana=@9,@FechaInicio=@10,@FechaFin=@11,@Activo=@12`,
      [
        id,
        usuarioId,
        'categoriaId' in dto ? dto.categoriaId ?? null : null,
        'cuentaId' in dto ? dto.cuentaId ?? null : null,
        'metodoPagoId' in dto ? dto.metodoPagoId ?? null : null,
        'monto' in dto ? dto.monto ?? null : null,
        'descripcion' in dto ? dto.descripcion ?? null : null,
        'frecuencia' in dto ? dto.frecuencia ?? null : null,
        'diaVencimiento' in dto ? dto.diaVencimiento ?? null : null,
        'diaSemana' in dto ? dto.diaSemana ?? null : null,
        'fechaInicio' in dto ? dto.fechaInicio ?? null : null,
        'fechaFin' in dto ? dto.fechaFin ?? null : null,
        'activo' in dto ? (dto as any).activo ?? null : null,
      ],
    );
    return result[0];
  }

  async toggle(usuarioId: number, id: number, activo: boolean) {
    const result = await this.connection.manager.query(
      `EXEC sp_pago_recurrente_toggle @Id=@0,@UsuarioId=@1,@Activo=@2`,
      [id, usuarioId, activo ? 1 : 0],
    );
    return result[0];
  }

  async remove(usuarioId: number, id: number) {
    await this.connection.manager.query(
      `EXEC sp_pago_recurrente_delete @Id=@0,@UsuarioId=@1`,
      [id, usuarioId],
    );
    return { success: true };
  }

  async executeNow(usuarioId: number, id: number, fecha?: string | Date) {
    const fechaEjecucion = fecha
      ? typeof fecha === 'string'
        ? new Date(fecha)
        : fecha
      : new Date();
    const result = await this.connection.manager.query(
      `EXEC sp_pago_recurrente_execute_now @Id=@0,@UsuarioId=@1,@FechaEjecucion=@2`,
      [id, usuarioId, fechaEjecucion],
    );
    return result[0];
  }
}


