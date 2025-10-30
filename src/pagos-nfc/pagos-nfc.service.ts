import { Injectable } from '@nestjs/common';
import { InjectConnection } from '@nestjs/typeorm';
import { Connection } from 'typeorm';
import { CreatePagoNfcDto } from './dto/create-pago-nfc.dto';

@Injectable()
export class PagosNfcService {
  constructor(@InjectConnection() private readonly connection: Connection) {}

  private ensureArray<T = any>(data: any): T[] {
    if (Array.isArray(data)) return data as T[];
    if (data === undefined || data === null) return [] as T[];
    return [data] as T[];
  }

  async create(usuarioId: number, dto: CreatePagoNfcDto) {
    const fecha = dto.fechaTransaccion ? new Date(dto.fechaTransaccion) : null;
    const res = await this.connection.manager.query(
      `EXEC sp_pago_nfc_create @UsuarioId=@0,@TarjetaId=@1,@DispositivoNfcId=@2,@Monto=@3,@FechaTransaccion=@4,@CuentaId=@5,@CategoriaId=@6,@Descripcion=@7,@Ubicacion=@8,@Lat=@9,@Lon=@10`,
      [
        usuarioId,
        dto.tarjetaId,
        dto.dispositivoNfcId,
        dto.monto,
        fecha,
        dto.cuentaId ?? null,
        dto.categoriaId ?? null,
        dto.descripcion ?? null,
        dto.ubicacion ?? null,
        dto.lat ?? null,
        dto.lon ?? null,
      ],
    );
    return this.ensureArray(res)[0];
  }

  async findAll(usuarioId: number, tarjetaId?: number) {
    const res = await this.connection.manager.query(
      `EXEC sp_pago_nfc_get_by_user @UsuarioId=@0,@TarjetaId=@1`,
      [usuarioId, tarjetaId ?? null],
    );
    return this.ensureArray(res);
  }

  async findOne(usuarioId: number, id: number) {
    const res = await this.connection.manager.query(
      `EXEC sp_pago_nfc_get_by_id @Id=@0,@UsuarioId=@1`,
      [id, usuarioId],
    );
    return this.ensureArray(res)[0];
  }
}


