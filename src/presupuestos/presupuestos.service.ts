import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectConnection } from '@nestjs/typeorm';
import { Connection } from 'typeorm';
import { CreatePresupuestoDto } from './dto/create-presupuesto.dto';
import { UpdatePresupuestoDto } from './dto/update-presupuesto.dto';

@Injectable()
export class PresupuestosService {
  constructor(@InjectConnection() private readonly connection: Connection) {}

  private ensureArray<T = any>(data: any): T[] {
    if (Array.isArray(data)) return data as T[];
    if (data === undefined || data === null) return [] as T[];
    return [data] as T[];
  }

  async create(usuarioId: number, dto: CreatePresupuestoDto) {
    // Convertir strings ISO a Date para que TypeORM los envíe como DATETIME2
    const fechaInicio = dto.fechaInicio ? new Date(dto.fechaInicio) : null;
    const fechaFin = dto.fechaFin ? new Date(dto.fechaFin) : null;

    const res = await this.connection.manager.query(
      `EXEC sp_presupuesto_create @UsuarioId=@0,@Nombre=@1,@Periodo=@2,@FechaInicio=@3,@FechaFin=@4,@MontoLimite=@5,@CategoriaId=@6,@CuentaId=@7,@Notas=@8`,
      [
        usuarioId,
        dto.nombre,
        dto.periodo,
        fechaInicio,
        fechaFin,
        dto.montoLimite,
        dto.categoriaId ?? null,
        dto.cuentaId ?? null,
        dto.notas ?? null,
      ],
    );
    return this.ensureArray(res)[0];
  }

  async findAll(usuarioId: number, soloActivos?: boolean) {
    const res = await this.connection.manager.query(
      `EXEC sp_presupuesto_get_by_user @UsuarioId=@0,@SoloActivos=@1`,
      [usuarioId, soloActivos === undefined ? null : soloActivos ? 1 : 0],
    );
    return this.ensureArray(res);
  }

  async findOne(usuarioId: number, id: number) {
    const res = await this.connection.manager.query(
      `EXEC sp_presupuesto_get_by_id @Id=@0,@UsuarioId=@1`,
      [id, usuarioId],
    );
    const row = this.ensureArray(res)[0];
    if (!row) throw new NotFoundException('Presupuesto no encontrado');
    return row;
  }

  async update(usuarioId: number, id: number, dto: UpdatePresupuestoDto) {
    // Convertir strings ISO a Date para que TypeORM los envíe como DATETIME2
    const fechaInicio = dto.fechaInicio ? new Date(dto.fechaInicio) : undefined;
    const fechaFin = dto.fechaFin ? new Date(dto.fechaFin) : undefined;

    const res = await this.connection.manager.query(
      `EXEC sp_presupuesto_update @Id=@0,@UsuarioId=@1,@Nombre=@2,@Periodo=@3,@FechaInicio=@4,@FechaFin=@5,@MontoLimite=@6,@CategoriaId=@7,@CuentaId=@8,@Activo=@9,@Notas=@10`,
      [
        id,
        usuarioId,
        dto.nombre,
        dto.periodo,
        fechaInicio,
        fechaFin,
        dto.montoLimite,
        dto.categoriaId,
        dto.cuentaId,
        dto.activo,
        dto.notas,
      ],
    );
    return this.ensureArray(res)[0];
  }

  async toggle(usuarioId: number, id: number, activo: boolean) {
    const res = await this.connection.manager.query(
      `EXEC sp_presupuesto_toggle @Id=@0,@UsuarioId=@1,@Activo=@2`,
      [id, usuarioId, activo ? 1 : 0],
    );
    return this.ensureArray(res)[0];
  }

  async remove(usuarioId: number, id: number) {
    await this.connection.manager.query(
      `EXEC sp_presupuesto_delete @Id=@0,@UsuarioId=@1`,
      [id, usuarioId],
    );
    return { success: true };
  }

  async recalc(usuarioId: number, id: number) {
    const res = await this.connection.manager.query(
      `EXEC sp_presupuesto_recalc_gasto @Id=@0,@UsuarioId=@1`,
      [id, usuarioId],
    );
    return this.ensureArray(res)[0];
  }

  async resumen(usuarioId: number, fecha?: string) {
    const res = await this.connection.manager.query(
      `EXEC sp_presupuesto_resumen @UsuarioId=@0,@Fecha=@1`,
      [usuarioId, fecha ?? null],
    );
    return this.ensureArray(res)[0];
  }
}


