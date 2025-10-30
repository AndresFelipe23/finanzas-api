import { Injectable, Logger, NotFoundException, ConflictException, BadRequestException, Inject } from '@nestjs/common';
import { InjectConnection } from '@nestjs/typeorm';
import { Connection } from 'typeorm';
import { CreateCategoriaDto } from './dto/create-categoria.dto';
import { UpdateCategoriaDto } from './dto/update-categoria.dto';
import { CategoriaResponseDto } from './dto/categoria-response.dto';

@Injectable()
export class CategoriasService {
  private readonly logger = new Logger(CategoriasService.name);

  constructor(
    @InjectConnection()
    private readonly connection: Connection,
  ) {}

  /**
   * Crea una nueva categoría para el usuario
   */
  async create(usuarioId: number, createCategoriaDto: CreateCategoriaDto): Promise<CategoriaResponseDto> {
    try {
      const { nombre, icono, color, tipo } = createCategoriaDto;

      // Validar el tipo
      if (tipo && !['INGRESO', 'GASTO', 'AMBOS'].includes(tipo)) {
        throw new BadRequestException('El tipo debe ser INGRESO, GASTO o AMBOS');
      }

      // Verificar si la categoría ya existe para este usuario
      const existing = await this.connection.manager.query(
        'SELECT id FROM categorias WHERE usuario_id = @0 AND nombre = @1',
        [usuarioId, nombre]
      );

      if (existing && existing.length > 0) {
        throw new ConflictException('Ya existe una categoría con este nombre');
      }

      // Insertar la nueva categoría
      const insertQuery = `
        INSERT INTO categorias (usuario_id, nombre, icono, color, tipo, activo, fecha_creacion)
        OUTPUT INSERTED.id, INSERTED.usuario_id, INSERTED.nombre, INSERTED.icono, INSERTED.color, INSERTED.tipo, INSERTED.activo, INSERTED.fecha_creacion
        VALUES (@0, @1, @2, @3, @4, 1, GETDATE())
      `;

      const result = await this.connection.manager.query(insertQuery, [
        usuarioId,
        nombre,
        icono || null,
        color || null,
        tipo || 'GASTO',
      ]);

      return this.mapToResponseDto(result[0]);
    } catch (error) {
      this.logger.error(`Error al crear categoría: ${error.message}`);
      
      if (error instanceof ConflictException || error instanceof BadRequestException) {
        throw error;
      }
      
      throw new Error(`Error al crear categoría: ${error.message}`);
    }
  }

  /**
   * Obtiene todas las categorías activas del usuario (excluye categorías del sistema)
   */
  async findAllByUser(usuarioId: number): Promise<CategoriaResponseDto[]> {
    try {
      const query = `
        SELECT id, usuario_id, nombre, icono, color, tipo, activo, fecha_creacion
        FROM categorias
        WHERE usuario_id = @0 AND activo = 1
        ORDER BY tipo, nombre
      `;

      const categorias = await this.connection.manager.query(query, [usuarioId]);

      return categorias.map(cat => this.mapToResponseDto(cat));
    } catch (error) {
      this.logger.error(`Error al obtener categorías: ${error.message}`);
      throw new Error(`Error al obtener categorías: ${error.message}`);
    }
  }

  /**
   * Obtiene categorías por tipo para el usuario
   */
  async findByType(usuarioId: number, tipo: 'INGRESO' | 'GASTO' | 'AMBOS'): Promise<CategoriaResponseDto[]> {
    try {
      if (!['INGRESO', 'GASTO', 'AMBOS'].includes(tipo)) {
        throw new BadRequestException('El tipo debe ser INGRESO, GASTO o AMBOS');
      }

      const query = `
        SELECT id, usuario_id, nombre, icono, color, tipo, activo, fecha_creacion
        FROM categorias
        WHERE usuario_id = @0 
          AND activo = 1
          AND (tipo = @1 OR tipo = 'AMBOS')
        ORDER BY nombre
      `;

      const categorias = await this.connection.manager.query(query, [usuarioId, tipo]);

      return categorias.map(cat => this.mapToResponseDto(cat));
    } catch (error) {
      this.logger.error(`Error al obtener categorías por tipo: ${error.message}`);
      throw new Error(`Error al obtener categorías por tipo: ${error.message}`);
    }
  }

  /**
   * Obtiene una categoría específica por su ID
   * Solo devuelve categorías que pertenecen al usuario (no del sistema)
   */
  async findOne(categoriaId: number, usuarioId: number): Promise<CategoriaResponseDto> {
    try {
      const query = `
        SELECT id, usuario_id, nombre, icono, color, tipo, activo, fecha_creacion
        FROM categorias
        WHERE id = @0 AND activo = 1
      `;

      const result = await this.connection.manager.query(query, [categoriaId]);

      if (!result || result.length === 0) {
        throw new NotFoundException('Categoría no encontrada');
      }

      const categoria = result[0];

      // Verificar que la categoría pertenece al usuario
      // NO permitir acceso a categorías del sistema (usuario_id = NULL)
      const categoriaUsuarioId = categoria.usuario_id ? parseInt(categoria.usuario_id) : null;
      
      // Si es categoría del sistema, no permitir acceso
      if (categoriaUsuarioId === null) {
        throw new NotFoundException('Categoría no encontrada');
      }
      
      // Si no pertenece al usuario, no permitir acceso
      if (categoriaUsuarioId !== usuarioId) {
        throw new NotFoundException('Categoría no encontrada');
      }

      return this.mapToResponseDto(categoria);
    } catch (error) {
      this.logger.error(`Error al obtener categoría: ${error.message}`);
      
      if (error instanceof NotFoundException) {
        throw error;
      }
      
      throw new Error(`Error al obtener categoría: ${error.message}`);
    }
  }

  /**
   * Actualiza una categoría
   * No se pueden actualizar categorías del sistema (usuario_id = NULL)
   */
  async update(categoriaId: number, usuarioId: number, updateCategoriaDto: UpdateCategoriaDto): Promise<CategoriaResponseDto> {
    try {
      // Verificar que la categoría existe y pertenece al usuario (no del sistema)
      await this.findOne(categoriaId, usuarioId);

      const updateFields: string[] = [];
      const params: any[] = [];
      let paramIndex = 0;

      if (updateCategoriaDto.nombre !== undefined) {
        updateFields.push(`nombre = @${paramIndex}`);
        params.push(updateCategoriaDto.nombre);
        paramIndex++;
      }

      if (updateCategoriaDto.icono !== undefined) {
        updateFields.push(`icono = @${paramIndex}`);
        params.push(updateCategoriaDto.icono);
        paramIndex++;
      }

      if (updateCategoriaDto.color !== undefined) {
        updateFields.push(`color = @${paramIndex}`);
        params.push(updateCategoriaDto.color);
        paramIndex++;
      }

      if (updateCategoriaDto.tipo !== undefined) {
        if (!['INGRESO', 'GASTO', 'AMBOS'].includes(updateCategoriaDto.tipo)) {
          throw new BadRequestException('El tipo debe ser INGRESO, GASTO o AMBOS');
        }
        updateFields.push(`tipo = @${paramIndex}`);
        params.push(updateCategoriaDto.tipo);
        paramIndex++;
      }

      if (updateCategoriaDto.activo !== undefined) {
        updateFields.push(`activo = @${paramIndex}`);
        params.push(updateCategoriaDto.activo ? 1 : 0);
        paramIndex++;
      }

      if (updateFields.length === 0) {
        return await this.findOne(categoriaId, usuarioId);
      }

      params.push(categoriaId);

      const updateQuery = `
        UPDATE categorias
        SET ${updateFields.join(', ')}
        OUTPUT INSERTED.id, INSERTED.usuario_id, INSERTED.nombre, INSERTED.icono, INSERTED.color, INSERTED.tipo, INSERTED.activo, INSERTED.fecha_creacion
        WHERE id = @${paramIndex}
      `;

      const result = await this.connection.manager.query(updateQuery, params);

      return this.mapToResponseDto(result[0]);
    } catch (error) {
      this.logger.error(`Error al actualizar categoría: ${error.message}`);
      
      if (error instanceof NotFoundException || error instanceof BadRequestException) {
        throw error;
      }
      
      throw new Error(`Error al actualizar categoría: ${error.message}`);
    }
  }

  /**
   * Elimina una categoría físicamente de la base de datos
   * No se puede eliminar si tiene transacciones asociadas
   * No se pueden eliminar categorías del sistema (usuario_id = NULL)
   */
  async remove(categoriaId: number, usuarioId: number): Promise<{ message: string }> {
    try {
      // Verificar que la categoría existe y pertenece al usuario (no del sistema)
      await this.findOne(categoriaId, usuarioId);

      // Verificar si la categoría tiene transacciones
      const transacciones = await this.connection.manager.query(
        'SELECT COUNT(*) as count FROM transacciones WHERE categoria_id = @0 AND activa = 1',
        [categoriaId]
      );

      const count = transacciones[0].count;
      
      if (count > 0) {
        throw new ConflictException(
          `No se puede eliminar la categoría porque tiene ${count} transacción(es) asociada(s)`
        );
      }

      // Realizar eliminación física
      await this.connection.manager.query(
        'DELETE FROM categorias WHERE id = @0',
        [categoriaId]
      );

      return { message: 'Categoría eliminada exitosamente' };
    } catch (error) {
      this.logger.error(`Error al eliminar categoría: ${error.message}`);
      
      if (error instanceof NotFoundException || error instanceof ConflictException) {
        throw error;
      }
      
      throw new Error(`Error al eliminar categoría: ${error.message}`);
    }
  }

  /**
   * Obtiene estadísticas de uso de categorías para el usuario
   */
  async getSummary(usuarioId: number): Promise<any[]> {
    try {
      // Obtener IDs de tipos de transacción
      const tiposIngreso = await this.connection.manager.query(
        'SELECT id FROM tipos_transaccion WHERE nombre = @0',
        ['INGRESO']
      );

      const tiposGasto = await this.connection.manager.query(
        'SELECT id FROM tipos_transaccion WHERE nombre = @0',
        ['GASTO']
      );

      const tipoIngresoId = tiposIngreso[0]?.id;
      const tipoGastoId = tiposGasto[0]?.id;

      const query = `
        SELECT 
          c.id,
          c.nombre,
          c.tipo,
          c.color,
          c.icono,
          COUNT(t.id) AS total_transacciones,
          COALESCE(SUM(CASE WHEN t.tipo_transaccion_id = @0 THEN t.monto ELSE 0 END), 0) AS total_ingresos,
          COALESCE(SUM(CASE WHEN t.tipo_transaccion_id = @1 THEN t.monto ELSE 0 END), 0) AS total_gastos
        FROM categorias c
        LEFT JOIN transacciones t ON c.id = t.categoria_id 
          AND t.usuario_id = @2 
          AND t.activa = 1
        WHERE c.usuario_id = @2 
          AND c.activo = 1
        GROUP BY c.id, c.nombre, c.tipo, c.color, c.icono
        ORDER BY total_transacciones DESC, c.nombre
      `;

      const summary = await this.connection.manager.query(query, [tipoIngresoId, tipoGastoId, usuarioId]);

      return summary;
    } catch (error) {
      this.logger.error(`Error al obtener resumen de categorías: ${error.message}`);
      throw new Error(`Error al obtener resumen de categorías: ${error.message}`);
    }
  }

  /**
   * Inserta categorías predeterminadas para un usuario nuevo
   */
  async insertDefaultCategories(usuarioId: number): Promise<{ message: string }> {
    try {
      // Verificar si el usuario ya tiene categorías
      const existing = await this.connection.manager.query(
        'SELECT COUNT(*) as count FROM categorias WHERE usuario_id = @0',
        [usuarioId]
      );

      if (existing[0].count > 0) {
        throw new ConflictException('El usuario ya tiene categorías personalizadas');
      }

      // Insertar categorías predeterminadas
      const gastoCategories = [
        { nombre: 'Alimentación', color: '#FF6B6B', icono: 'restaurant' },
        { nombre: 'Transporte', color: '#4ECDC4', icono: 'directions_car' },
        { nombre: 'Salud', color: '#45B7D1', icono: 'local_hospital' },
        { nombre: 'Educación', color: '#FFA07A', icono: 'school' },
        { nombre: 'Entretenimiento', color: '#98D8C8', icono: 'sports_esports' },
        { nombre: 'Ropa', color: '#F7DC6F', icono: 'checkroom' },
        { nombre: 'Vivienda', color: '#BB8FCE', icono: 'home' },
        { nombre: 'Facturas', color: '#85C1E2', icono: 'receipt' },
        { nombre: 'Supermercado', color: '#F1948A', icono: 'shopping_cart' },
        { nombre: 'Otros Gastos', color: '#95A5A6', icono: 'more_horiz' },
      ];

      const ingresoCategories = [
        { nombre: 'Salario', color: '#10B981', icono: 'work' },
        { nombre: 'Freelance', color: '#6366F1', icono: 'computer' },
        { nombre: 'Inversiones', color: '#8B5CF6', icono: 'trending_up' },
        { nombre: 'Bonos', color: '#EC4899', icono: 'card_giftcard' },
        { nombre: 'Otros Ingresos', color: '#14B8A6', icono: 'attach_money' },
      ];

      for (const cat of gastoCategories) {
        await this.connection.manager.query(
          `INSERT INTO categorias (usuario_id, nombre, tipo, color, icono, activo, fecha_creacion)
           VALUES (@0, @1, @2, @3, @4, 1, GETDATE())`,
          [usuarioId, cat.nombre, 'GASTO', cat.color, cat.icono]
        );
      }

      for (const cat of ingresoCategories) {
        await this.connection.manager.query(
          `INSERT INTO categorias (usuario_id, nombre, tipo, color, icono, activo, fecha_creacion)
           VALUES (@0, @1, @2, @3, @4, 1, GETDATE())`,
          [usuarioId, cat.nombre, 'INGRESO', cat.color, cat.icono]
        );
      }

      return { message: 'Categorías predeterminadas creadas exitosamente' };
    } catch (error) {
      this.logger.error(`Error al crear categorías predeterminadas: ${error.message}`);
      
      if (error instanceof ConflictException) {
        throw error;
      }
      
      throw new Error(`Error al crear categorías predeterminadas: ${error.message}`);
    }
  }

  /**
   * Mapea los datos de la categoría a DTO de respuesta
   */
  private mapToResponseDto(categoria: any): CategoriaResponseDto {
    return {
      id: parseInt(categoria.id),
      usuario_id: categoria.usuario_id ? parseInt(categoria.usuario_id) : undefined,
      nombre: categoria.nombre,
      icono: categoria.icono,
      color: categoria.color,
      tipo: categoria.tipo,
      activo: Boolean(categoria.activo),
      fecha_creacion: categoria.fecha_creacion,
    };
  }
}

