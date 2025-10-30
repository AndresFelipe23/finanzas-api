import { Injectable, Logger, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectConnection } from '@nestjs/typeorm';
import { Connection } from 'typeorm';
import { CreateMetaDto } from './dto/create-meta.dto';
import { UpdateMetaDto } from './dto/update-meta.dto';
import { MetaResponseDto } from './dto/meta-response.dto';
import { CreateAporteDto } from './dto/create-aporte.dto';

@Injectable()
export class MetasService {
  private readonly logger = new Logger(MetasService.name);

  constructor(
    @InjectConnection()
    private readonly connection: Connection,
  ) {}

  /**
   * Crea una nueva meta para el usuario
   */
  async create(usuarioId: number, createMetaDto: CreateMetaDto): Promise<MetaResponseDto> {
    try {
      const result = await this.connection.manager.query(
        `EXEC sp_meta_create 
          @UsuarioId=@0, @Nombre=@1, @Descripcion=@2, @MontoObjetivo=@3, 
          @FechaObjetivo=@4, @Icono=@5, @Color=@6`,
        [
          usuarioId,
          createMetaDto.nombre,
          createMetaDto.descripcion || null,
          createMetaDto.montoObjetivo,
          createMetaDto.fechaObjetivo,
          createMetaDto.icono || null,
          createMetaDto.color || null,
        ],
      );

      return this.mapToResponseDto(result[0]);
    } catch (error) {
      this.logger.error(`Error al crear meta: ${error.message}`);
      throw new Error(`Error al crear meta: ${error.message}`);
    }
  }

  /**
   * Obtiene todas las metas del usuario con filtro opcional
   */
  async findAll(usuarioId: number, filtro: 'ACTIVAS' | 'COMPLETADAS' | 'TODAS' = 'TODAS'): Promise<MetaResponseDto[]> {
    try {
      const result = await this.connection.manager.query(
        `EXEC sp_meta_get_by_user @UsuarioId=@0, @Filtro=@1`,
        [usuarioId, filtro],
      );

      if (!result || !Array.isArray(result)) {
        return [];
      }

      return result.map((meta) => {
        try {
          return this.mapToResponseDto(meta);
        } catch (error) {
          this.logger.error(`Error al mapear meta: ${error.message}`, meta);
          throw error;
        }
      });
    } catch (error) {
      this.logger.error(`Error al obtener metas: ${error.message}`);
      throw new Error(`Error al obtener metas: ${error.message}`);
    }
  }

  /**
   * Obtiene una meta específica por su ID
   */
  async findOne(id: number, usuarioId: number): Promise<MetaResponseDto> {
    try {
      const result = await this.connection.manager.query(
        `EXEC sp_meta_get_by_id @Id=@0, @UsuarioId=@1`,
        [id, usuarioId],
      );

      if (!result || result.length === 0) {
        throw new NotFoundException('Meta no encontrada');
      }

      return this.mapToResponseDto(result[0]);
    } catch (error) {
      this.logger.error(`Error al obtener meta: ${error.message}`);
      
      if (error instanceof NotFoundException) {
        throw error;
      }
      
      throw new Error(`Error al obtener meta: ${error.message}`);
    }
  }

  /**
   * Actualiza una meta
   */
  async update(id: number, usuarioId: number, updateMetaDto: UpdateMetaDto): Promise<MetaResponseDto> {
    try {
      const result = await this.connection.manager.query(
        `EXEC sp_meta_update 
          @Id=@0, @UsuarioId=@1, @Nombre=@2, @Descripcion=@3, @MontoObjetivo=@4,
          @FechaObjetivo=@5, @Icono=@6, @Color=@7, @Activa=@8`,
        [
          id,
          usuarioId,
          'nombre' in updateMetaDto ? updateMetaDto.nombre ?? null : null,
          'descripcion' in updateMetaDto ? updateMetaDto.descripcion ?? null : null,
          'montoObjetivo' in updateMetaDto ? updateMetaDto.montoObjetivo ?? null : null,
          'fechaObjetivo' in updateMetaDto ? updateMetaDto.fechaObjetivo ?? null : null,
          'icono' in updateMetaDto ? updateMetaDto.icono ?? null : null,
          'color' in updateMetaDto ? updateMetaDto.color ?? null : null,
          'activa' in updateMetaDto ? (updateMetaDto.activa ?? null) : null,
        ],
      );

      if (!result || result.length === 0) {
        throw new NotFoundException('Meta no encontrada');
      }

      return this.mapToResponseDto(result[0]);
    } catch (error) {
      this.logger.error(`Error al actualizar meta: ${error.message}`);
      
      if (error instanceof NotFoundException) {
        throw error;
      }
      
      throw new Error(`Error al actualizar meta: ${error.message}`);
    }
  }

  /**
   * Elimina una meta
   */
  async remove(id: number, usuarioId: number): Promise<{ message: string }> {
    try {
      await this.connection.manager.query(
        `EXEC sp_meta_delete @Id=@0, @UsuarioId=@1`,
        [id, usuarioId],
      );

      return { message: 'Meta eliminada exitosamente' };
    } catch (error) {
      this.logger.error(`Error al eliminar meta: ${error.message}`);
      throw new Error(`Error al eliminar meta: ${error.message}`);
    }
  }

  /**
   * Activa o desactiva una meta
   */
  async toggleActiva(id: number, usuarioId: number, activa: boolean): Promise<MetaResponseDto> {
    try {
      const result = await this.connection.manager.query(
        `EXEC sp_meta_toggle_activa @Id=@0, @UsuarioId=@1, @Activa=@2`,
        [id, usuarioId, activa ? 1 : 0],
      );

      if (!result || result.length === 0) {
        throw new NotFoundException('Meta no encontrada');
      }

      return this.mapToResponseDto(result[0]);
    } catch (error) {
      this.logger.error(`Error al cambiar estado de meta: ${error.message}`);
      
      if (error instanceof NotFoundException) {
        throw error;
      }
      
      throw new Error(`Error al cambiar estado de meta: ${error.message}`);
    }
  }

  /**
   * Crea un aporte para una meta
   */
  async createAporte(metaId: number, usuarioId: number, createAporteDto: CreateAporteDto): Promise<MetaResponseDto> {
    try {
      const result = await this.connection.manager.query(
        `EXEC sp_meta_aporte_create 
          @UsuarioId=@0, @MetaId=@1, @CuentaId=@2, @MontoAporte=@3, @Notas=@4`,
        [
          usuarioId,
          metaId,
          createAporteDto.cuentaId || null,
          createAporteDto.montoAporte,
          createAporteDto.notas || null,
        ],
      );

      if (!result || result.length === 0) {
        throw new NotFoundException('Meta no encontrada');
      }

      return this.mapToResponseDto(result[0]);
    } catch (error) {
      this.logger.error(`Error al crear aporte: ${error.message}`);
      
      if (error instanceof NotFoundException) {
        throw error;
      }
      
      throw new Error(`Error al crear aporte: ${error.message}`);
    }
  }

  /**
   * Obtiene todos los aportes de una meta
   */
  async findAportesByMeta(metaId: number, usuarioId: number): Promise<any[]> {
    try {
      const result = await this.connection.manager.query(
        `EXEC sp_meta_aportes_get_by_meta @UsuarioId=@0, @MetaId=@1`,
        [usuarioId, metaId],
      );

      return result;
    } catch (error) {
      this.logger.error(`Error al obtener aportes: ${error.message}`);
      throw new Error(`Error al obtener aportes: ${error.message}`);
    }
  }

  /**
   * Mapea los datos de la meta a DTO de respuesta
   */
  private mapToResponseDto(meta: any): MetaResponseDto {
    if (!meta) {
      throw new Error('Meta data is null or undefined');
    }

    // Helper para convertir a número de forma segura
    const toNumber = (value: any): number => {
      if (value === null || value === undefined) return 0;
      const num = typeof value === 'number' ? value : Number(value);
      return isNaN(num) ? 0 : num;
    };

    // Helper para convertir a número entero de forma segura
    const toInt = (value: any): number => {
      if (value === null || value === undefined) return 0;
      const num = typeof value === 'number' ? value : parseInt(String(value), 10);
      return isNaN(num) ? 0 : num;
    };

    return {
      id: toInt(meta.id),
      usuario_id: toInt(meta.usuario_id),
      nombre: meta.nombre || '',
      descripcion: meta.descripcion || null,
      monto_objetivo: toNumber(meta.monto_objetivo),
      monto_actual: toNumber(meta.monto_actual),
      fecha_objetivo: meta.fecha_objetivo || new Date(),
      icono: meta.icono || null,
      color: meta.color || null,
      activa: meta.activa !== null && meta.activa !== undefined ? Boolean(meta.activa) : true,
      fecha_creacion: meta.fecha_creacion || new Date(),
      fecha_actualizacion: meta.fecha_actualizacion || new Date(),
    };
  }
}

