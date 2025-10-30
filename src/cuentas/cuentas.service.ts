import { Injectable, Logger, NotFoundException, ConflictException, BadRequestException } from '@nestjs/common';
import { InjectConnection } from '@nestjs/typeorm';
import { Connection } from 'typeorm';
import { CreateCuentaDto } from './dto/create-cuenta.dto';
import { UpdateCuentaDto } from './dto/update-cuenta.dto';
import { CuentaResponseDto } from './dto/cuenta-response.dto';

@Injectable()
export class CuentasService {
  private readonly logger = new Logger(CuentasService.name);

  constructor(
    @InjectConnection()
    private readonly connection: Connection,
  ) {}

  /**
   * Crea una nueva cuenta para el usuario
   */
  async create(usuarioId: number, createCuentaDto: CreateCuentaDto): Promise<CuentaResponseDto> {
    try {
      const { nombre, tipo, moneda, saldoInicial, color, icono, descripcion } = createCuentaDto;

      // Validar el tipo
      const tipoValido = tipo || 'BANCARIA';
      if (!['BANCARIA', 'EFECTIVO', 'TARJETA_CREDITO', 'TARJETA_DEBITO', 'DIGITAL', 'AHORRO', 'INVERSION'].includes(tipoValido)) {
        throw new BadRequestException('El tipo de cuenta no es válido');
      }

      // Verificar si la cuenta ya existe para este usuario
      const existing = await this.connection.manager.query(
        'SELECT id FROM cuentas WHERE usuario_id = @0 AND nombre = @1 AND activa = 1',
        [usuarioId, nombre]
      );

      if (existing && existing.length > 0) {
        throw new ConflictException('Ya existe una cuenta con este nombre');
      }

      // Insertar la nueva cuenta
      const insertQuery = `
        INSERT INTO cuentas (usuario_id, nombre, tipo, moneda, saldo_inicial, color, icono, descripcion, activa, fecha_creacion)
        OUTPUT INSERTED.id, INSERTED.usuario_id, INSERTED.nombre, INSERTED.tipo, INSERTED.moneda, INSERTED.saldo_inicial, INSERTED.color, INSERTED.icono, INSERTED.descripcion, INSERTED.activa, INSERTED.fecha_creacion
        VALUES (@0, @1, @2, @3, @4, @5, @6, @7, 1, GETDATE())
      `;

      const result = await this.connection.manager.query(insertQuery, [
        usuarioId,
        nombre,
        tipoValido,
        moneda || 'COP',
        saldoInicial || 0,
        color || null,
        icono || null,
        descripcion || null,
      ]);

      return this.mapToResponseDto(result[0]);
    } catch (error) {
      this.logger.error(`Error al crear cuenta: ${error.message}`);
      
      if (error instanceof ConflictException || error instanceof BadRequestException) {
        throw error;
      }
      
      throw new Error(`Error al crear cuenta: ${error.message}`);
    }
  }

  /**
   * Obtiene todas las cuentas activas del usuario
   */
  async findAllByUser(usuarioId: number): Promise<CuentaResponseDto[]> {
    try {
      const query = `
        DECLARE @TipoIngresoId BIGINT;
        DECLARE @TipoGastoId BIGINT;
        
        SELECT @TipoIngresoId = id FROM tipos_transaccion WHERE nombre = 'INGRESO';
        SELECT @TipoGastoId = id FROM tipos_transaccion WHERE nombre = 'GASTO';
        
        SELECT 
          c.id,
          c.usuario_id,
          c.nombre,
          c.tipo,
          c.moneda,
          c.saldo_inicial,
          c.color,
          c.icono,
          c.descripcion,
          c.activa,
          c.fecha_creacion,
          c.saldo_inicial + ISNULL(
            SUM(CASE 
              WHEN t.tipo_transaccion_id = @TipoIngresoId THEN t.monto
              WHEN t.tipo_transaccion_id = @TipoGastoId THEN -t.monto
              ELSE 0
            END),
            0
          ) AS saldo_actual
        FROM cuentas c
        LEFT JOIN transacciones t ON c.id = t.cuenta_id 
          AND t.usuario_id = @0 
          AND t.activa = 1
        WHERE c.usuario_id = @0 
          AND c.activa = 1
        GROUP BY c.id, c.usuario_id, c.nombre, c.tipo, c.moneda, c.saldo_inicial, 
                 c.color, c.icono, c.descripcion, c.activa, c.fecha_creacion
        ORDER BY c.nombre
      `;

      const cuentas = await this.connection.manager.query(query, [usuarioId]);

      return cuentas.map(cuenta => this.mapToResponseDto(cuenta));
    } catch (error) {
      this.logger.error(`Error al obtener cuentas: ${error.message}`);
      throw new Error(`Error al obtener cuentas: ${error.message}`);
    }
  }

  /**
   * Obtiene una cuenta específica por su ID
   */
  async findOne(cuentaId: number, usuarioId: number): Promise<CuentaResponseDto> {
    try {
      const query = `
        DECLARE @TipoIngresoId BIGINT;
        DECLARE @TipoGastoId BIGINT;
        
        SELECT @TipoIngresoId = id FROM tipos_transaccion WHERE nombre = 'INGRESO';
        SELECT @TipoGastoId = id FROM tipos_transaccion WHERE nombre = 'GASTO';
        
        SELECT 
          c.id,
          c.usuario_id,
          c.nombre,
          c.tipo,
          c.moneda,
          c.saldo_inicial,
          c.color,
          c.icono,
          c.descripcion,
          c.activa,
          c.fecha_creacion,
          c.saldo_inicial + ISNULL(
            SUM(CASE 
              WHEN t.tipo_transaccion_id = @TipoIngresoId THEN t.monto
              WHEN t.tipo_transaccion_id = @TipoGastoId THEN -t.monto
              ELSE 0
            END),
            0
          ) AS saldo_actual
        FROM cuentas c
        LEFT JOIN transacciones t ON c.id = t.cuenta_id 
          AND t.usuario_id = @0
          AND t.activa = 1
        WHERE c.id = @1
          AND c.usuario_id = @0
          AND c.activa = 1
        GROUP BY c.id, c.usuario_id, c.nombre, c.tipo, c.moneda, c.saldo_inicial, 
                 c.color, c.icono, c.descripcion, c.activa, c.fecha_creacion
      `;

      const result = await this.connection.manager.query(query, [usuarioId, cuentaId]);

      if (!result || result.length === 0) {
        throw new NotFoundException('Cuenta no encontrada');
      }

      return this.mapToResponseDto(result[0]);
    } catch (error) {
      this.logger.error(`Error al obtener cuenta: ${error.message}`);
      
      if (error instanceof NotFoundException) {
        throw error;
      }
      
      throw new Error(`Error al obtener cuenta: ${error.message}`);
    }
  }

  /**
   * Actualiza una cuenta
   */
  async update(cuentaId: number, usuarioId: number, updateCuentaDto: UpdateCuentaDto): Promise<CuentaResponseDto> {
    try {
      // Verificar que la cuenta existe y pertenece al usuario
      await this.findOne(cuentaId, usuarioId);

      const updateFields: string[] = [];
      const params: any[] = [];
      let paramIndex = 0;

      if (updateCuentaDto.nombre !== undefined) {
        updateFields.push(`nombre = @${paramIndex}`);
        params.push(updateCuentaDto.nombre);
        paramIndex++;
      }

      if (updateCuentaDto.tipo !== undefined) {
        if (!['BANCARIA', 'EFECTIVO', 'TARJETA_CREDITO', 'TARJETA_DEBITO', 'DIGITAL', 'AHORRO', 'INVERSION'].includes(updateCuentaDto.tipo)) {
          throw new BadRequestException('El tipo de cuenta no es válido');
        }
        updateFields.push(`tipo = @${paramIndex}`);
        params.push(updateCuentaDto.tipo);
        paramIndex++;
      }

      if (updateCuentaDto.moneda !== undefined) {
        updateFields.push(`moneda = @${paramIndex}`);
        params.push(updateCuentaDto.moneda);
        paramIndex++;
      }

      if (updateCuentaDto.saldoInicial !== undefined) {
        updateFields.push(`saldo_inicial = @${paramIndex}`);
        params.push(updateCuentaDto.saldoInicial);
        paramIndex++;
      }

      if (updateCuentaDto.color !== undefined) {
        updateFields.push(`color = @${paramIndex}`);
        params.push(updateCuentaDto.color);
        paramIndex++;
      }

      if (updateCuentaDto.icono !== undefined) {
        updateFields.push(`icono = @${paramIndex}`);
        params.push(updateCuentaDto.icono);
        paramIndex++;
      }

      if (updateCuentaDto.descripcion !== undefined) {
        updateFields.push(`descripcion = @${paramIndex}`);
        params.push(updateCuentaDto.descripcion);
        paramIndex++;
      }

      if (updateCuentaDto.activa !== undefined) {
        updateFields.push(`activa = @${paramIndex}`);
        params.push(updateCuentaDto.activa ? 1 : 0);
        paramIndex++;
      }

      if (updateFields.length === 0) {
        return await this.findOne(cuentaId, usuarioId);
      }

      params.push(cuentaId);

      const updateQuery = `
        UPDATE cuentas
        SET ${updateFields.join(', ')}
        OUTPUT INSERTED.id, INSERTED.usuario_id, INSERTED.nombre, INSERTED.tipo, INSERTED.moneda, INSERTED.saldo_inicial, INSERTED.color, INSERTED.icono, INSERTED.descripcion, INSERTED.activa, INSERTED.fecha_creacion
        WHERE id = @${paramIndex}
      `;

      const result = await this.connection.manager.query(updateQuery, params);

      return this.mapToResponseDto(result[0]);
    } catch (error) {
      this.logger.error(`Error al actualizar cuenta: ${error.message}`);
      
      if (error instanceof NotFoundException || error instanceof BadRequestException) {
        throw error;
      }
      
      throw new Error(`Error al actualizar cuenta: ${error.message}`);
    }
  }

  /**
   * Elimina una cuenta (soft delete)
   */
  async remove(cuentaId: number, usuarioId: number): Promise<{ message: string }> {
    try {
      // Verificar que la cuenta existe y pertenece al usuario
      await this.findOne(cuentaId, usuarioId);

      // Verificar si la cuenta tiene transacciones
      const transacciones = await this.connection.manager.query(
        'SELECT COUNT(*) as count FROM transacciones WHERE cuenta_id = @0 AND activa = 1',
        [cuentaId]
      );

      const count = transacciones[0].count;
      
      if (count > 0) {
        throw new ConflictException(
          `No se puede eliminar la cuenta porque tiene ${count} transacción(es) asociada(s)`
        );
      }

      // Calcular el saldo actual
      const cuenta = await this.findOne(cuentaId, usuarioId);
      
      if (cuenta.saldo_actual && cuenta.saldo_actual !== 0) {
        throw new ConflictException(
          'No se puede eliminar la cuenta porque tiene saldo'
        );
      }

      // Realizar eliminación física
      await this.connection.manager.query(
        'DELETE FROM cuentas WHERE id = @0',
        [cuentaId]
      );

      return { message: 'Cuenta eliminada exitosamente' };
    } catch (error) {
      this.logger.error(`Error al eliminar cuenta: ${error.message}`);
      
      if (error instanceof NotFoundException || error instanceof ConflictException) {
        throw error;
      }
      
      throw new Error(`Error al eliminar cuenta: ${error.message}`);
    }
  }

  /**
   * Obtiene cuentas por tipo
   */
  async findByType(usuarioId: number, tipo: string): Promise<CuentaResponseDto[]> {
    try {
      if (!['BANCARIA', 'EFECTIVO', 'TARJETA_CREDITO', 'TARJETA_DEBITO', 'DIGITAL', 'AHORRO', 'INVERSION'].includes(tipo)) {
        throw new BadRequestException('El tipo de cuenta no es válido');
      }

      const query = `
        DECLARE @TipoIngresoId BIGINT;
        DECLARE @TipoGastoId BIGINT;
        
        SELECT @TipoIngresoId = id FROM tipos_transaccion WHERE nombre = 'INGRESO';
        SELECT @TipoGastoId = id FROM tipos_transaccion WHERE nombre = 'GASTO';
        
        SELECT 
          c.id,
          c.usuario_id,
          c.nombre,
          c.tipo,
          c.moneda,
          c.saldo_inicial,
          c.color,
          c.icono,
          c.descripcion,
          c.activa,
          c.fecha_creacion,
          c.saldo_inicial + ISNULL(
            SUM(CASE 
              WHEN t.tipo_transaccion_id = @TipoIngresoId THEN t.monto
              WHEN t.tipo_transaccion_id = @TipoGastoId THEN -t.monto
              ELSE 0
            END),
            0
          ) AS saldo_actual
        FROM cuentas c
        LEFT JOIN transacciones t ON c.id = t.cuenta_id 
          AND t.usuario_id = @0 
          AND t.activa = 1
        WHERE c.usuario_id = @0 
          AND c.tipo = @1
          AND c.activa = 1
        GROUP BY c.id, c.usuario_id, c.nombre, c.tipo, c.moneda, c.saldo_inicial, 
                 c.color, c.icono, c.descripcion, c.activa, c.fecha_creacion
        ORDER BY c.nombre
      `;

      const cuentas = await this.connection.manager.query(query, [usuarioId, tipo]);

      return cuentas.map(cuenta => this.mapToResponseDto(cuenta));
    } catch (error) {
      this.logger.error(`Error al obtener cuentas por tipo: ${error.message}`);
      throw new Error(`Error al obtener cuentas por tipo: ${error.message}`);
    }
  }

  /**
   * Obtiene estadísticas de uso de cuentas
   */
  async getSummary(usuarioId: number): Promise<any[]> {
    try {
      const query = `
        DECLARE @TipoIngresoId BIGINT;
        DECLARE @TipoGastoId BIGINT;
        
        SELECT @TipoIngresoId = id FROM tipos_transaccion WHERE nombre = 'INGRESO';
        SELECT @TipoGastoId = id FROM tipos_transaccion WHERE nombre = 'GASTO';
        
        SELECT 
          c.id,
          c.nombre,
          c.tipo,
          c.moneda,
          c.saldo_inicial,
          c.color,
          c.icono,
          COUNT(t.id) AS total_transacciones,
          c.saldo_inicial + ISNULL(
            SUM(CASE 
              WHEN t.tipo_transaccion_id = @TipoIngresoId THEN t.monto
              WHEN t.tipo_transaccion_id = @TipoGastoId THEN -t.monto
              ELSE 0
            END),
            0
          ) AS saldo_actual,
          ISNULL(SUM(CASE 
            WHEN t.tipo_transaccion_id = @TipoIngresoId THEN t.monto
            ELSE 0
          END), 0) AS total_ingresos,
          ISNULL(SUM(CASE 
            WHEN t.tipo_transaccion_id = @TipoGastoId THEN t.monto
            ELSE 0
          END), 0) AS total_gastos
        FROM cuentas c
        LEFT JOIN transacciones t ON c.id = t.cuenta_id 
          AND t.usuario_id = @0 
          AND t.activa = 1
        WHERE c.usuario_id = @0 
          AND c.activa = 1
        GROUP BY c.id, c.nombre, c.tipo, c.moneda, c.saldo_inicial, c.color, c.icono
        ORDER BY saldo_actual DESC, c.nombre
      `;

      const summary = await this.connection.manager.query(query, [usuarioId]);

      return summary;
    } catch (error) {
      this.logger.error(`Error al obtener resumen de cuentas: ${error.message}`);
      throw new Error(`Error al obtener resumen de cuentas: ${error.message}`);
    }
  }

  /**
   * Mapea los datos de la cuenta a DTO de respuesta
   */
  private mapToResponseDto(cuenta: any): CuentaResponseDto {
    return {
      id: parseInt(cuenta.id),
      usuario_id: parseInt(cuenta.usuario_id),
      nombre: cuenta.nombre,
      tipo: cuenta.tipo,
      moneda: cuenta.moneda,
      saldo_inicial: parseFloat(cuenta.saldo_inicial) || 0,
      color: cuenta.color,
      icono: cuenta.icono,
      descripcion: cuenta.descripcion,
      activa: Boolean(cuenta.activa),
      fecha_creacion: cuenta.fecha_creacion,
      saldo_actual: cuenta.saldo_actual ? parseFloat(cuenta.saldo_actual) : undefined,
    };
  }
}

