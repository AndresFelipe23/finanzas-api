import { Injectable, BadRequestException, NotFoundException, Logger } from '@nestjs/common';
import { InjectConnection } from '@nestjs/typeorm';
import { Connection } from 'typeorm';
import { CreatePrestamoDto } from './dto/create-prestamo.dto';
import { UpdatePrestamoDto } from './dto/update-prestamo.dto';
import { CreatePagoPrestamoDto } from './dto/create-pago-prestamo.dto';
import { UpdatePagoPrestamoDto } from './dto/update-pago-prestamo.dto';

@Injectable()
export class PrestamosService {
  private readonly logger = new Logger(PrestamosService.name);

  constructor(@InjectConnection() private readonly connection: Connection) {}

  private ensureArray<T = any>(data: any): T[] {
    if (Array.isArray(data)) return data as T[];
    if (data === undefined || data === null) return [] as T[];
    return [data] as T[];
  }

  async create(usuarioId: number, dto: CreatePrestamoDto) {
    const result = await this.connection.manager.query(
      `EXEC sp_prestamo_create @UsuarioId=@0,@Nombre=@1,@Tipo=@2,@MontoTotal=@3,@TasaInteres=@4,@FechaInicio=@5,@FechaFin=@6,@CuentaId=@7,@Notas=@8`,
      [
        usuarioId,
        dto.nombre,
        dto.tipo,
        dto.montoTotal,
        dto.tasaInteres ?? null,
        dto.fechaInicio ?? null,
        dto.fechaFin ?? null,
        dto.cuentaId ?? null,
        dto.notas ?? null,
      ],
    );
    return this.ensureArray(result)[0];
  }

  async findAll(usuarioId: number, activosSolo?: boolean) {
    const result = await this.connection.manager.query(
      `EXEC sp_prestamo_get_by_user @UsuarioId=@0,@ActivosSolo=@1`,
      [usuarioId, activosSolo === undefined ? null : activosSolo ? 1 : 0],
    );
    return this.ensureArray(result);
  }

  async findOne(usuarioId: number, id: number) {
    const result = await this.connection.manager.query(
      `EXEC sp_prestamo_get_by_id @Id=@0,@UsuarioId=@1`,
      [id, usuarioId],
    );
    const row = this.ensureArray(result)[0];
    if (!row) throw new NotFoundException('Préstamo no encontrado');
    return row;
  }

  async update(usuarioId: number, id: number, dto: UpdatePrestamoDto) {
    const result = await this.connection.manager.query(
      `EXEC sp_prestamo_update @Id=@0,@UsuarioId=@1,@Nombre=@2,@Tipo=@3,@MontoTotal=@4,@TasaInteres=@5,@FechaInicio=@6,@FechaFin=@7,@CuentaId=@8,@Notas=@9,@Activa=@10`,
      [
        id,
        usuarioId,
        'nombre' in dto ? dto.nombre ?? null : null,
        'tipo' in dto ? dto.tipo ?? null : null,
        'montoTotal' in dto ? dto.montoTotal ?? null : null,
        'tasaInteres' in dto ? dto.tasaInteres ?? null : null,
        'fechaInicio' in dto ? dto.fechaInicio ?? null : null,
        'fechaFin' in dto ? dto.fechaFin ?? null : null,
        'cuentaId' in dto ? dto.cuentaId ?? null : null,
        'notas' in dto ? dto.notas ?? null : null,
        'activa' in dto ? (dto as any).activa ?? null : null,
      ],
    );
    return this.ensureArray(result)[0];
  }

  async toggle(usuarioId: number, id: number, activa: boolean) {
    const result = await this.connection.manager.query(
      `EXEC sp_prestamo_toggle_activo @Id=@0,@UsuarioId=@1,@Activa=@2`,
      [id, usuarioId, activa ? 1 : 0],
    );
    return this.ensureArray(result)[0];
  }

  async remove(usuarioId: number, id: number) {
    await this.connection.manager.query(
      `EXEC sp_prestamo_delete @Id=@0,@UsuarioId=@1`,
      [id, usuarioId],
    );
    return { success: true };
  }

  // PAGOS
  async createPago(usuarioId: number, dto: CreatePagoPrestamoDto) {
    const result = await this.connection.manager.query(
      `EXEC sp_prestamo_pago_create @UsuarioId=@0,@PrestamoId=@1,@Monto=@2,@FechaPago=@3,@CuentaId=@4,@Notas=@5`,
      [
        usuarioId,
        dto.prestamoId,
        dto.monto,
        dto.fechaPago ?? null,
        dto.cuentaId ?? null,
        dto.notas ?? null,
      ],
    );
    return this.ensureArray(result)[0];
  }

  async updatePago(usuarioId: number, pagoId: number, dto: UpdatePagoPrestamoDto) {
    const result = await this.connection.manager.query(
      `EXEC sp_prestamo_pago_update @UsuarioId=@0,@PagoId=@1,@Monto=@2,@FechaPago=@3,@CuentaId=@4,@Notas=@5`,
      [
        usuarioId,
        pagoId,
        'monto' in dto ? dto.monto ?? null : null,
        'fechaPago' in dto ? dto.fechaPago ?? null : null,
        'cuentaId' in dto ? dto.cuentaId ?? null : null,
        'notas' in dto ? dto.notas ?? null : null,
      ],
    );
    return this.ensureArray(result)[0];
  }

  async removePago(usuarioId: number, pagoId: number) {
    await this.connection.manager.query(
      `EXEC sp_prestamo_pago_delete @UsuarioId=@0,@PagoId=@1`,
      [usuarioId, pagoId],
    );
    return { success: true };
  }

  async listPagos(usuarioId: number, prestamoId: number) {
    const result = await this.connection.manager.query(
      `EXEC sp_prestamo_pagos_get_by_prestamo @UsuarioId=@0,@PrestamoId=@1`,
      [usuarioId, prestamoId],
    );
    return this.ensureArray(result);
  }
}


