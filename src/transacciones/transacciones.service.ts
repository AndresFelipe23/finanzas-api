import { Injectable, Logger, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectConnection } from '@nestjs/typeorm';
import { Connection } from 'typeorm';
import { CreateTransaccionDto } from './dto/create-transaccion.dto';
import { UpdateTransaccionDto } from './dto/update-transaccion.dto';
import { TransaccionResponseDto } from './dto/transaccion-response.dto';

@Injectable()
export class TransaccionesService {
  private readonly logger = new Logger(TransaccionesService.name);

  constructor(
    @InjectConnection()
    private readonly connection: Connection,
  ) {}

  /**
   * Crea una nueva transacción
   */
  async create(usuarioId: number, createTransaccionDto: CreateTransaccionDto): Promise<TransaccionResponseDto> {
    try {
      const {
        cuentaId,
        tipoTransaccionId,
        categoriaId,
        metodoPagoId,
        monto,
        moneda,
        descripcion,
        titulo,
        fechaTransaccion,
        archivoAdjunto,
        notas,
        repetir,
      } = createTransaccionDto;

      // Validaciones
      if (monto <= 0) {
        throw new BadRequestException('El monto debe ser mayor que cero');
      }

      // Si se envía fechaTransaccion, usar la fecha del usuario pero con la hora actual del sistema
      // Si no se envía, usar fecha y hora actual del sistema
      let fechaValida: Date;
      if (fechaTransaccion) {
        const str = fechaTransaccion as unknown as string;
        // Parsear la fecha enviada (solo fecha, hora será del sistema)
        const m = str.match(/^(\d{4})-(\d{2})-(\d{2})(?:[T\s](\d{2}):(\d{2})(?::(\d{2}))?)?$/);
        if (m) {
          const y = Number(m[1]);
          const mo = Number(m[2]) - 1;
          const d = Number(m[3]);
          // Usar la fecha del usuario pero con la hora actual del sistema
          const ahora = new Date();
          fechaValida = new Date(y, mo, d, ahora.getHours(), ahora.getMinutes(), ahora.getSeconds(), ahora.getMilliseconds());
        } else {
          // Si no se puede parsear, usar fecha y hora actual
          fechaValida = new Date();
        }
      } else {
        // Si no se envía fecha, usar fecha y hora actual del sistema
        fechaValida = new Date();
      }

      // Preparar parámetros
      const params = [
        usuarioId,
        cuentaId !== undefined && cuentaId !== null ? cuentaId : null,
        tipoTransaccionId,
        categoriaId !== undefined && categoriaId !== null ? categoriaId : null,
        metodoPagoId !== undefined && metodoPagoId !== null ? metodoPagoId : null,
        monto,
        moneda || 'COP',
        titulo !== undefined && titulo !== null && titulo !== '' ? titulo : null,
        descripcion !== undefined && descripcion !== null && descripcion !== '' ? descripcion : null,
        fechaValida,
        archivoAdjunto !== undefined && archivoAdjunto !== null && archivoAdjunto !== '' ? archivoAdjunto : null,
        notas !== undefined && notas !== null && notas !== '' ? notas : null,
        repetir ? 1 : 0,
      ];

      this.logger.debug(`Creando transacción con parámetros: ${JSON.stringify(params)}`);

      // Insertar la transacción usando el stored procedure
      const result = await this.connection.manager.query(
        `EXEC sp_transaccion_create 
          @UsuarioId = @0,
          @CuentaId = @1,
          @TipoTransaccionId = @2,
          @CategoriaId = @3,
          @MetodoPagoId = @4,
          @Monto = @5,
          @Moneda = @6,
          @Titulo = @7,
          @Descripcion = @8,
          @FechaTransaccion = @9,
          @ArchivoAdjunto = @10,
          @Notas = @11,
          @Repetir = @12`,
        params
      );

      this.logger.debug(`Resultado del stored procedure: ${JSON.stringify(result)}`);

      // Validar que se retornó un resultado
      if (!result || result.length === 0) {
        throw new Error('No se recibió respuesta del servidor al crear la transacción');
      }

      this.logger.debug(`Mapeando transacción: ${JSON.stringify(result[0])}`);
      return this.mapToResponseDto(result[0]);
    } catch (error) {
      this.logger.error(`Error al crear transacción: ${error.message}`);
      this.logger.error(`Stack trace: ${error.stack}`);
      
      if (error instanceof BadRequestException) {
        throw error;
      }
      
      // Capturar errores de saldo insuficiente del stored procedure
      if (error.message && error.message.includes('Saldo insuficiente')) {
        throw new BadRequestException(error.message);
      }
      
      // Capturar errores de formato numérico
      if (error.message && error.message.includes('Invalid radix-10 number')) {
        this.logger.error('Error de formato numérico - posible problema con valores NULL');
        throw new Error('Error al procesar la respuesta del servidor. Por favor, intente nuevamente.');
      }
      
      throw new Error(`Error al crear transacción: ${error.message}`);
    }
  }

  /**
   * Obtiene todas las transacciones del usuario
   */
  async findAllByUser(
    usuarioId: number,
    fechaInicio?: Date,
    fechaFin?: Date
  ): Promise<TransaccionResponseDto[]> {
    try {
      const result = await this.connection.manager.query(
        `EXEC sp_transaccion_get_by_user
          @UsuarioId = @0,
          @FechaInicio = @1,
          @FechaFin = @2`,
        [
          usuarioId,
          fechaInicio || null,
          fechaFin || null,
        ]
      );

      return result.map(item => this.mapToResponseDto(item));
    } catch (error) {
      this.logger.error(`Error al obtener transacciones: ${error.message}`);
      throw new Error(`Error al obtener transacciones: ${error.message}`);
    }
  }

  /**
   * Obtiene una transacción específica por su ID
   */
  async findOne(transaccionId: number, usuarioId: number): Promise<TransaccionResponseDto> {
    try {
      const result = await this.connection.manager.query(
        `EXEC sp_transaccion_get_by_id
          @Id = @0,
          @UsuarioId = @1`,
        [transaccionId, usuarioId]
      );

      if (!result || result.length === 0) {
        throw new NotFoundException('Transacción no encontrada');
      }

      return this.mapToResponseDto(result[0]);
    } catch (error) {
      this.logger.error(`Error al obtener transacción: ${error.message}`);
      
      if (error instanceof NotFoundException) {
        throw error;
      }
      
      throw new Error(`Error al obtener transacción: ${error.message}`);
    }
  }

  /**
   * Actualiza una transacción
   */
  async update(
    transaccionId: number,
    usuarioId: number,
    updateTransaccionDto: UpdateTransaccionDto
  ): Promise<TransaccionResponseDto> {
    try {
      // Verificar que la transacción existe (sin validar si está activa)
      // Esto permite restaurar transacciones eliminadas
      const exists = await this.connection.manager.query(
        `SELECT 1 FROM transacciones WHERE id = @0 AND usuario_id = @1`,
        [transaccionId, usuarioId]
      );
      
      if (!exists || exists.length === 0) {
        throw new NotFoundException('Transacción no encontrada');
      }

      const updateFields: string[] = [];
      const params: any[] = [];
      let paramIndex = 0;

      if (updateTransaccionDto.cuentaId !== undefined) {
        updateFields.push(`@CuentaId = @${paramIndex}`);
        params.push(updateTransaccionDto.cuentaId);
        paramIndex++;
      } else {
        updateFields.push(`@CuentaId = NULL`);
      }

      if (updateTransaccionDto.tipoTransaccionId !== undefined) {
        updateFields.push(`@TipoTransaccionId = @${paramIndex}`);
        params.push(updateTransaccionDto.tipoTransaccionId);
        paramIndex++;
      } else {
        updateFields.push(`@TipoTransaccionId = NULL`);
      }

      if (updateTransaccionDto.categoriaId !== undefined) {
        updateFields.push(`@CategoriaId = @${paramIndex}`);
        params.push(updateTransaccionDto.categoriaId);
        paramIndex++;
      } else {
        updateFields.push(`@CategoriaId = NULL`);
      }

      if (updateTransaccionDto.metodoPagoId !== undefined) {
        updateFields.push(`@MetodoPagoId = @${paramIndex}`);
        params.push(updateTransaccionDto.metodoPagoId);
        paramIndex++;
      } else {
        updateFields.push(`@MetodoPagoId = NULL`);
      }

      if (updateTransaccionDto.monto !== undefined) {
        updateFields.push(`@Monto = @${paramIndex}`);
        params.push(updateTransaccionDto.monto);
        paramIndex++;
      } else {
        updateFields.push(`@Monto = NULL`);
      }

      if (updateTransaccionDto.moneda !== undefined) {
        updateFields.push(`@Moneda = @${paramIndex}`);
        params.push(updateTransaccionDto.moneda);
        paramIndex++;
      } else {
        updateFields.push(`@Moneda = NULL`);
      }

      if (updateTransaccionDto.descripcion !== undefined) {
        updateFields.push(`@Descripcion = @${paramIndex}`);
        params.push(updateTransaccionDto.descripcion);
        paramIndex++;
      } else {
        updateFields.push(`@Descripcion = NULL`);
      }

      if (updateTransaccionDto.fechaTransaccion !== undefined) {
        updateFields.push(`@FechaTransaccion = @${paramIndex}`);
        // Parsear la fecha enviada (solo fecha, hora será del sistema)
        const str = updateTransaccionDto.fechaTransaccion as unknown as string;
        const m = str.match(/^(\d{4})-(\d{2})-(\d{2})(?:[T\s](\d{2}):(\d{2})(?::(\d{2}))?)?$/);
        let fechaValida: Date;
        if (m) {
          const y = Number(m[1]);
          const mo = Number(m[2]) - 1;
          const d = Number(m[3]);
          // Usar la fecha del usuario pero con la hora actual del sistema
          const ahora = new Date();
          fechaValida = new Date(y, mo, d, ahora.getHours(), ahora.getMinutes(), ahora.getSeconds(), ahora.getMilliseconds());
        } else {
          fechaValida = new Date(updateTransaccionDto.fechaTransaccion);
        }
        params.push(fechaValida);
        paramIndex++;
      } else {
        updateFields.push(`@FechaTransaccion = NULL`);
      }

      if (updateTransaccionDto.archivoAdjunto !== undefined) {
        updateFields.push(`@ArchivoAdjunto = @${paramIndex}`);
        params.push(updateTransaccionDto.archivoAdjunto);
        paramIndex++;
      } else {
        updateFields.push(`@ArchivoAdjunto = NULL`);
      }

      if (updateTransaccionDto.notas !== undefined) {
        updateFields.push(`@Notas = @${paramIndex}`);
        params.push(updateTransaccionDto.notas);
        paramIndex++;
      } else {
        updateFields.push(`@Notas = NULL`);
      }

      if (updateTransaccionDto.repetir !== undefined) {
        updateFields.push(`@Repetir = @${paramIndex}`);
        params.push(updateTransaccionDto.repetir ? 1 : 0);
        paramIndex++;
      } else {
        updateFields.push(`@Repetir = NULL`);
      }

      if (updateTransaccionDto.activa !== undefined) {
        updateFields.push(`@Activa = @${paramIndex}`);
        params.push(updateTransaccionDto.activa ? 1 : 0);
        paramIndex++;
      } else {
        updateFields.push(`@Activa = NULL`);
      }

      params.push(transaccionId, usuarioId);

      const result = await this.connection.manager.query(
        `EXEC sp_transaccion_update
          @Id = @${paramIndex},
          @UsuarioId = @${paramIndex + 1},
          ${updateFields.join(', ')}`,
        params
      );

      return this.mapToResponseDto(result[0]);
    } catch (error) {
      this.logger.error(`Error al actualizar transacción: ${error.message}`);
      
      if (error instanceof NotFoundException || error instanceof BadRequestException) {
        throw error;
      }
      
      throw new Error(`Error al actualizar transacción: ${error.message}`);
    }
  }

  /**
   * Elimina una transacción (soft delete)
   */
  async remove(transaccionId: number, usuarioId: number): Promise<{ message: string }> {
    try {
      // Verificar que la transacción existe (sin validar si está activa)
      const exists = await this.connection.manager.query(
        `SELECT 1 FROM transacciones WHERE id = @0 AND usuario_id = @1`,
        [transaccionId, usuarioId]
      );
      
      if (!exists || exists.length === 0) {
        throw new NotFoundException('Transacción no encontrada');
      }

      await this.connection.manager.query(
        `EXEC sp_transaccion_delete
          @Id = @0,
          @UsuarioId = @1`,
        [transaccionId, usuarioId]
      );

      return { message: 'Transacción eliminada exitosamente' };
    } catch (error) {
      this.logger.error(`Error al eliminar transacción: ${error.message}`);
      
      if (error instanceof NotFoundException) {
        throw error;
      }
      
      throw new Error(`Error al eliminar transacción: ${error.message}`);
    }
  }

  /**
   * Elimina una transacción permanentemente (hard delete)
   */
  async removePermanently(transaccionId: number, usuarioId: number): Promise<{ message: string }> {
    try {
      // Verificar que la transacción existe (sin validar si está activa)
      const exists = await this.connection.manager.query(
        `SELECT 1 FROM transacciones WHERE id = @0 AND usuario_id = @1`,
        [transaccionId, usuarioId]
      );
      
      if (!exists || exists.length === 0) {
        throw new NotFoundException('Transacción no encontrada');
      }

      await this.connection.manager.query(
        `EXEC sp_transaccion_delete_permanently
          @Id = @0,
          @UsuarioId = @1`,
        [transaccionId, usuarioId]
      );

      return { message: 'Transacción eliminada permanentemente' };
    } catch (error) {
      this.logger.error(`Error al eliminar transacción permanentemente: ${error.message}`);
      
      if (error instanceof NotFoundException) {
        throw error;
      }
      
      throw new Error(`Error al eliminar transacción permanentemente: ${error.message}`);
    }
  }

  /**
   * Obtiene transacciones por cuenta
   */
  async findByAccount(
    usuarioId: number,
    cuentaId: number,
    fechaInicio?: Date,
    fechaFin?: Date
  ): Promise<TransaccionResponseDto[]> {
    try {
      const result = await this.connection.manager.query(
        `EXEC sp_transaccion_get_by_account
          @UsuarioId = @0,
          @CuentaId = @1,
          @FechaInicio = @2,
          @FechaFin = @3`,
        [
          usuarioId,
          cuentaId,
          fechaInicio || null,
          fechaFin || null,
        ]
      );

      return result.map(item => this.mapToResponseDto(item));
    } catch (error) {
      this.logger.error(`Error al obtener transacciones por cuenta: ${error.message}`);
      throw new Error(`Error al obtener transacciones por cuenta: ${error.message}`);
    }
  }

  /**
   * Obtiene transacciones por categoría
   */
  async findByCategory(
    usuarioId: number,
    categoriaId: number,
    fechaInicio?: Date,
    fechaFin?: Date
  ): Promise<TransaccionResponseDto[]> {
    try {
      const result = await this.connection.manager.query(
        `EXEC sp_transaccion_get_by_category
          @UsuarioId = @0,
          @CategoriaId = @1,
          @FechaInicio = @2,
          @FechaFin = @3`,
        [
          usuarioId,
          categoriaId,
          fechaInicio || null,
          fechaFin || null,
        ]
      );

      return result.map(item => this.mapToResponseDto(item));
    } catch (error) {
      this.logger.error(`Error al obtener transacciones por categoría: ${error.message}`);
      throw new Error(`Error al obtener transacciones por categoría: ${error.message}`);
    }
  }

  /**
   * Obtiene el resumen de transacciones con estadísticas
   */
  async getSummary(
    usuarioId: number,
    fechaInicio?: Date,
    fechaFin?: Date
  ): Promise<any[]> {
    try {
      const result = await this.connection.manager.query(
        `EXEC sp_transaccion_get_summary
          @UsuarioId = @0,
          @FechaInicio = @1,
          @FechaFin = @2`,
        [
          usuarioId,
          fechaInicio || null,
          fechaFin || null,
        ]
      );

      return result;
    } catch (error) {
      this.logger.error(`Error al obtener resumen: ${error.message}`);
      throw new Error(`Error al obtener resumen: ${error.message}`);
    }
  }

  /**
   * Crea una transferencia entre dos cuentas
   */
  async createTransfer(
    usuarioId: number,
    cuentaOrigenId: number,
    cuentaDestinoId: number,
    monto: number,
    moneda?: string,
    titulo?: string,
    descripcion?: string,
    fechaTransaccion?: string,
    notas?: string
  ): Promise<TransaccionResponseDto[]> {
    try {
      // Validaciones
      if (monto <= 0) {
        throw new BadRequestException('El monto debe ser mayor que cero');
      }

      if (cuentaOrigenId === cuentaDestinoId) {
        throw new BadRequestException('La cuenta de origen y destino no pueden ser la misma');
      }

      let fechaValida: Date;
      if (fechaTransaccion) {
        const str = fechaTransaccion as unknown as string;
        // Parse local YYYY-MM-DD or YYYY-MM-DDTHH:mm:ss
        const m = str.match(/^(\d{4})-(\d{2})-(\d{2})(?:[T\s](\d{2}):(\d{2})(?::(\d{2}))?)?$/);
        if (m) {
          const y = Number(m[1]);
          const mo = Number(m[2]) - 1;
          const d = Number(m[3]);
          const hh = m[4] ? Number(m[4]) : 0;
          const mm = m[5] ? Number(m[5]) : 0;
          const ss = m[6] ? Number(m[6]) : 0;
          fechaValida = new Date(y, mo, d, hh, mm, ss); // Local time
        } else {
          fechaValida = new Date(str);
        }
        if (isNaN(fechaValida.getTime())) {
          throw new BadRequestException('La fecha de transacción no es válida');
        }
      } else {
        fechaValida = new Date();
      }

      // Crear la transferencia usando el stored procedure
      const result = await this.connection.manager.query(
        `EXEC sp_transaccion_create_transfer
          @UsuarioId = @0,
          @CuentaOrigenId = @1,
          @CuentaDestinoId = @2,
          @Monto = @3,
          @Moneda = @4,
          @Titulo = @5,
          @Descripcion = @6,
          @FechaTransaccion = @7,
          @Notas = @8`,
        [
          usuarioId,
          cuentaOrigenId,
          cuentaDestinoId,
          monto,
          moneda || 'COP',
          titulo || null,
          descripcion || null,
          fechaValida,
          notas || null,
        ]
      );

      return result.map(item => this.mapToResponseDto(item));
    } catch (error) {
      this.logger.error(`Error al crear transferencia: ${error.message}`);
      
      if (error instanceof BadRequestException) {
        throw error;
      }
      
      throw new Error(`Error al crear transferencia: ${error.message}`);
    }
  }

  /**
   * Mapea los datos de la transacción a DTO de respuesta
   * Convierte las fechas a strings en formato local para evitar problemas de zona horaria
   */
  private mapToResponseDto(transaccion: any): TransaccionResponseDto {
    if (!transaccion) {
      throw new Error('Transacción es null o undefined');
    }

    // Función para convertir fecha a string en formato local (sin Z, sin conversión UTC)
    const formatDateAsLocalString = (date: any): string => {
      if (!date || date === null || date === 'null') return null as any;
      
      let dateObj: Date;
      
      // Si ya es string de SQL Server, parsearlo como local
      if (typeof date === 'string') {
        const str = date.toString().trim();
        if (str === 'null' || str === '') return null as any;
        // Formato SQL Server: "2026-01-03 20:57:23.0533333"
        if (str.includes(' ')) {
          const [datePart, timePart] = str.split(' ');
          const [year, month, day] = datePart.split('-').map(Number);
          const [hour, minute, secondPart] = timePart.split(':');
          const [second, msPart] = secondPart.split('.');
          const ms = msPart ? parseInt(msPart.substring(0, 3).padEnd(3, '0')) : 0;
          
          // Crear Date como hora local
          dateObj = new Date(year, month - 1, day, parseInt(hour), parseInt(minute), parseInt(second), ms);
        } else {
          // Si es ISO string sin Z, parsear como local
          dateObj = new Date(str);
        }
      } else if (date instanceof Date) {
        dateObj = date;
      } else {
        return null as any;
      }
      
      // Formatear como string local sin Z (formato: YYYY-MM-DDTHH:mm:ss)
      const year = dateObj.getFullYear();
      const month = String(dateObj.getMonth() + 1).padStart(2, '0');
      const day = String(dateObj.getDate()).padStart(2, '0');
      const hours = String(dateObj.getHours()).padStart(2, '0');
      const minutes = String(dateObj.getMinutes()).padStart(2, '0');
      const seconds = String(dateObj.getSeconds()).padStart(2, '0');
      
      return `${year}-${month}-${day}T${hours}:${minutes}:${seconds}`;
    };

    // Función helper para parsear enteros de forma segura
    const safeParseInt = (value: any): number => {
      if (value === null || value === undefined || value === 'null' || value === '' || value === 'NULL') {
        throw new Error(`Valor inválido para parseInt: ${value}`);
      }
      if (typeof value === 'number') return value;
      const parsed = parseInt(String(value), 10);
      if (isNaN(parsed)) {
        throw new Error(`No se pudo parsear como entero: ${value}`);
      }
      return parsed;
    };

    // Función helper para parsear decimales de forma segura
    const safeParseFloat = (value: any): number => {
      if (value === null || value === undefined || value === 'null' || value === '' || value === 'NULL') return 0;
      if (typeof value === 'number') return value;
      const parsed = parseFloat(String(value));
      return isNaN(parsed) ? 0 : parsed;
    };

    // Función helper para valores opcionales
    const safeOptionalInt = (value: any): number | undefined => {
      if (value === null || value === undefined || value === 'null' || value === '' || value === 'NULL') return undefined;
      if (typeof value === 'number') return value;
      const parsed = parseInt(String(value), 10);
      return isNaN(parsed) ? undefined : parsed;
    };

    try {
      return {
        id: safeParseInt(transaccion.id),
        usuario_id: safeParseInt(transaccion.usuario_id),
        cuenta_id: safeOptionalInt(transaccion.cuenta_id),
        cuenta_nombre: transaccion.cuenta_nombre || undefined,
        tipo_transaccion_id: safeParseInt(transaccion.tipo_transaccion_id),
        tipo_nombre: transaccion.tipo_nombre || '',
        categoria_id: safeOptionalInt(transaccion.categoria_id),
        categoria_nombre: transaccion.categoria_nombre || undefined,
        categoria_color: transaccion.categoria_color || undefined,
        categoria_icono: transaccion.categoria_icono || undefined,
        metodo_pago_id: safeOptionalInt(transaccion.metodo_pago_id),
        metodo_pago_nombre: transaccion.metodo_pago_nombre || undefined,
        monto: safeParseFloat(transaccion.monto),
        moneda: transaccion.moneda || 'COP',
        titulo: transaccion.titulo || undefined,
        descripcion: transaccion.descripcion || undefined,
        fecha_transaccion: formatDateAsLocalString(transaccion.fecha_transaccion),
        archivo_adjunto: transaccion.archivo_adjunto || undefined,
        notas: transaccion.notas || undefined,
        repetir: Boolean(transaccion.repetir),
        activa: Boolean(transaccion.activa),
        fecha_creacion: formatDateAsLocalString(transaccion.fecha_creacion),
      };
    } catch (error) {
      this.logger.error(`Error al mapear transacción: ${error.message}`);
      this.logger.error(`Datos de transacción: ${JSON.stringify(transaccion)}`);
      throw new Error(`Error al procesar la transacción: ${error.message}`);
    }
  }
}

