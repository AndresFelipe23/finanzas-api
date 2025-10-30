import { Injectable } from '@nestjs/common';
import { InjectConnection } from '@nestjs/typeorm';
import { Connection } from 'typeorm';
import { RegisterDispositivoDto } from './dto/register-dispositivo.dto';

@Injectable()
export class DispositivosNfcService {
  constructor(@InjectConnection() private readonly connection: Connection) {}

  private ensureArray<T>(res: any): T[] {
    return Array.isArray(res) ? res : [];
  }

  async registerOrGet(usuarioId: number, dto: RegisterDispositivoDto) {
    // Buscar por identificador_unico y usuario actual
    const found = await this.connection.manager.query(
      `SELECT TOP 1 * FROM dispositivos_nfc
       WHERE identificador_unico=@0 AND usuario_id=@1`,
      [dto.identificador_unico, usuarioId],
    );
    const rows = this.ensureArray<any>(found);

    // Si ya existe para este usuario, devolverlo
    if (rows.length > 0) {
      return rows[0];
    }

    // Verificar si existe para otro usuario (solo para logging, no bloqueamos)
    const existsForOther = await this.connection.manager.query(
      `SELECT TOP 1 id FROM dispositivos_nfc WHERE identificador_unico=@0 AND usuario_id<>@1`,
      [dto.identificador_unico, usuarioId],
    );

    // Si existe para otro usuario, significa que el dispositivo cambió de usuario
    // Esto es normal (ej: reinstalación de app, cambio de usuario en el dispositivo)
    // Simplemente creamos un nuevo registro para el usuario actual

    // Insertar nuevo registro para este usuario
    await this.connection.manager.query(
      `INSERT INTO dispositivos_nfc (usuario_id, nombre, tipo_dispositivo, identificador_unico, activo, fecha_registro)
       VALUES (@0, @1, @2, @3, 1, GETDATE())`,
      [usuarioId, dto.nombre, dto.tipo_dispositivo, dto.identificador_unico],
    );

    const inserted = await this.connection.manager.query(
      `SELECT TOP 1 * FROM dispositivos_nfc
       WHERE identificador_unico=@0 AND usuario_id=@1
       ORDER BY fecha_registro DESC`,
      [dto.identificador_unico, usuarioId],
    );

    return this.ensureArray<any>(inserted)[0];
  }
}


