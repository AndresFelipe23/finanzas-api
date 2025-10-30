import { Injectable } from '@nestjs/common';
import { InjectConnection } from '@nestjs/typeorm';
import { Connection } from 'typeorm';
import { CreateTarjetaNfcDto } from './dto/create-tarjeta-nfc.dto';
import { UpdateTarjetaNfcDto } from './dto/update-tarjeta-nfc.dto';

@Injectable()
export class TarjetasNfcService {
  constructor(@InjectConnection() private readonly connection: Connection) {}

  private ensureArray<T = any>(data: any): T[] {
    if (Array.isArray(data)) return data as T[];
    if (data === undefined || data === null) return [] as T[];
    return [data] as T[];
  }

  async create(usuarioId: number, dto: CreateTarjetaNfcDto) {
    const res = await this.connection.manager.query(
      `EXEC sp_tarjeta_nfc_create @UsuarioId=@0,@CuentaId=@1,@NombrePortador=@2,@NumeroTarjetaHash=@3,@Tipo=@4,@Banco=@5,@Color=@6`,
      [
        usuarioId,
        dto.cuentaId ?? null,
        dto.nombrePortador,
        dto.numeroTarjetaHash,
        dto.tipo,
        dto.banco ?? null,
        dto.color ?? null,
      ],
    );
    return this.ensureArray(res)[0];
  }

  async findAll(usuarioId: number, soloActivas?: boolean) {
    const res = await this.connection.manager.query(
      `EXEC sp_tarjeta_nfc_get_by_user @UsuarioId=@0,@SoloActivas=@1`,
      [usuarioId, soloActivas === undefined ? null : soloActivas ? 1 : 0],
    );
    return this.ensureArray(res);
  }

  async findOne(usuarioId: number, id: number) {
    const res = await this.connection.manager.query(
      `EXEC sp_tarjeta_nfc_get_by_id @Id=@0,@UsuarioId=@1`,
      [id, usuarioId],
    );
    return this.ensureArray(res)[0];
  }

  async update(usuarioId: number, id: number, dto: UpdateTarjetaNfcDto) {
    const res = await this.connection.manager.query(
      `EXEC sp_tarjeta_nfc_update @Id=@0,@UsuarioId=@1,@CuentaId=@2,@NombrePortador=@3,@Tipo=@4,@Banco=@5,@Color=@6`,
      [
        id,
        usuarioId,
        dto.cuentaId ?? null,
        dto.nombrePortador ?? null,
        dto.tipo ?? null,
        dto.banco ?? null,
        dto.color ?? null,
      ],
    );
    const row = this.ensureArray(res)[0];
    if (dto.activa !== undefined) {
      const res2 = await this.connection.manager.query(
        `EXEC sp_tarjeta_nfc_toggle @Id=@0,@UsuarioId=@1,@Activa=@2`,
        [id, usuarioId, dto.activa ? 1 : 0],
      );
      return this.ensureArray(res2)[0];
    }
    return row;
  }

  async toggle(usuarioId: number, id: number, activa: boolean) {
    const res = await this.connection.manager.query(
      `EXEC sp_tarjeta_nfc_toggle @Id=@0,@UsuarioId=@1,@Activa=@2`,
      [id, usuarioId, activa ? 1 : 0],
    );
    return this.ensureArray(res)[0];
  }

  async remove(usuarioId: number, id: number) {
    await this.connection.manager.query(
      `EXEC sp_tarjeta_nfc_delete @Id=@0,@UsuarioId=@1`,
      [id, usuarioId],
    );
    return { success: true };
  }
}


