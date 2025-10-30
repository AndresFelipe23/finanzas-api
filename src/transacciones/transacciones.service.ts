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
        [
          usuarioId,
          cuentaId || null,
          tipoTransaccionId,
          categoriaId || null,
          metodoPagoId || null,
          monto,
          moneda || 'COP',
          titulo || null,
          descripcion || null,
          fechaValida,
          archivoAdjunto || null,
          notas || null,
          repetir ? 1 : 0,
        ]
      );

      return this.mapToResponseDto(result[0]);
    } catch (error) {
      this.logger.error(`Error al crear transacción: ${error.message}`);
      
      if (error instanceof BadRequestException) {
        throw error;
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
      // Verificar que la transacción existe
      await this.findOne(transaccionId, usuarioId);

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
        params.push(updateTransaccionDto.fechaTransaccion);
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
      // Verificar que la transacción existe
      await this.findOne(transaccionId, usuarioId);

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
   */
  private mapToResponseDto(transaccion: any): TransaccionResponseDto {
    return {
      id: parseInt(transaccion.id),
      usuario_id: parseInt(transaccion.usuario_id),
      cuenta_id: transaccion.cuenta_id ? parseInt(transaccion.cuenta_id) : undefined,
      cuenta_nombre: transaccion.cuenta_nombre,
      tipo_transaccion_id: parseInt(transaccion.tipo_transaccion_id),
      tipo_nombre: transaccion.tipo_nombre,
      categoria_id: transaccion.categoria_id ? parseInt(transaccion.categoria_id) : undefined,
      categoria_nombre: transaccion.categoria_nombre,
      categoria_color: transaccion.categoria_color,
      categoria_icono: transaccion.categoria_icono,
      metodo_pago_id: transaccion.metodo_pago_id ? parseInt(transaccion.metodo_pago_id) : undefined,
      metodo_pago_nombre: transaccion.metodo_pago_nombre,
      monto: parseFloat(transaccion.monto) || 0,
      moneda: transaccion.moneda,
      titulo: transaccion.titulo,
      descripcion: transaccion.descripcion,
      fecha_transaccion: transaccion.fecha_transaccion,
      archivo_adjunto: transaccion.archivo_adjunto,
      notas: transaccion.notas,
      repetir: Boolean(transaccion.repetir),
      activa: Boolean(transaccion.activa),
      fecha_creacion: transaccion.fecha_creacion,
    };
  }
}

