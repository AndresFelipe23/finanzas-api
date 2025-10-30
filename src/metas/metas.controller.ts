import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  ParseIntPipe,
  Query,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';
import { MetasService } from './metas.service';
import { CreateMetaDto } from './dto/create-meta.dto';
import { UpdateMetaDto } from './dto/update-meta.dto';
import { MetaResponseDto } from './dto/meta-response.dto';
import { CreateAporteDto } from './dto/create-aporte.dto';

@ApiTags('Metas')
@Controller('metas')
export class MetasController {
  constructor(private readonly metasService: MetasService) {}

  @Post()
  @ApiOperation({
    summary: 'Crear meta',
    description: 'Crea una nueva meta financiera para el usuario autenticado',
  })
  @ApiResponse({
    status: 201,
    description: 'Meta creada exitosamente',
    type: MetaResponseDto,
  })
  @ApiBearerAuth()
  async create(@Body() createMetaDto: CreateMetaDto): Promise<MetaResponseDto> {
    // TODO: Extraer usuarioId del JWT cuando implementemos el guard
    const usuarioId = 1;
    return await this.metasService.create(usuarioId, createMetaDto);
  }

  @Get()
  @ApiOperation({
    summary: 'Obtener metas',
    description: 'Obtiene todas las metas del usuario autenticado con filtro opcional',
  })
  @ApiResponse({
    status: 200,
    description: 'Lista de metas',
    type: [MetaResponseDto],
  })
  @ApiBearerAuth()
  async findAll(
    @Query('filtro') filtro?: 'ACTIVAS' | 'COMPLETADAS' | 'TODAS',
  ): Promise<MetaResponseDto[]> {
    // TODO: Extraer usuarioId del JWT
    const usuarioId = 1;
    const filtroFinal = filtro || 'TODAS';
    return await this.metasService.findAll(usuarioId, filtroFinal);
  }

  @Get(':id')
  @ApiOperation({
    summary: 'Obtener meta',
    description: 'Obtiene una meta específica por su ID',
  })
  @ApiResponse({
    status: 200,
    description: 'Meta encontrada',
    type: MetaResponseDto,
  })
  @ApiResponse({
    status: 404,
    description: 'Meta no encontrada',
  })
  @ApiBearerAuth()
  async findOne(@Param('id', ParseIntPipe) id: number): Promise<MetaResponseDto> {
    // TODO: Extraer usuarioId del JWT
    const usuarioId = 1;
    return await this.metasService.findOne(id, usuarioId);
  }

  @Patch(':id')
  @ApiOperation({
    summary: 'Actualizar meta',
    description: 'Actualiza una meta existente',
  })
  @ApiResponse({
    status: 200,
    description: 'Meta actualizada exitosamente',
    type: MetaResponseDto,
  })
  @ApiResponse({
    status: 404,
    description: 'Meta no encontrada',
  })
  @ApiBearerAuth()
  async update(
    @Param('id', ParseIntPipe) id: number,
    @Body() updateMetaDto: UpdateMetaDto,
  ): Promise<MetaResponseDto> {
    // TODO: Extraer usuarioId del JWT
    const usuarioId = 1;
    return await this.metasService.update(id, usuarioId, updateMetaDto);
  }

  @Delete(':id')
  @ApiOperation({
    summary: 'Eliminar meta',
    description: 'Elimina una meta y todos sus aportes asociados',
  })
  @ApiResponse({
    status: 200,
    description: 'Meta eliminada exitosamente',
  })
  @ApiResponse({
    status: 404,
    description: 'Meta no encontrada',
  })
  @ApiBearerAuth()
  async remove(@Param('id', ParseIntPipe) id: number): Promise<{ message: string }> {
    // TODO: Extraer usuarioId del JWT
    const usuarioId = 1;
    return await this.metasService.remove(id, usuarioId);
  }

  @Patch(':id/toggle')
  @ApiOperation({
    summary: 'Activar/Desactivar meta',
    description: 'Activa o desactiva una meta',
  })
  @ApiResponse({
    status: 200,
    description: 'Estado de la meta actualizado exitosamente',
    type: MetaResponseDto,
  })
  @ApiResponse({
    status: 404,
    description: 'Meta no encontrada',
  })
  @ApiBearerAuth()
  async toggleActiva(
    @Param('id', ParseIntPipe) id: number,
    @Query('activa') activa: string,
  ): Promise<MetaResponseDto> {
    // TODO: Extraer usuarioId del JWT
    const usuarioId = 1;
    const activaBool = activa === 'true' || activa === '1';
    return await this.metasService.toggleActiva(id, usuarioId, activaBool);
  }

  @Post(':id/aportes')
  @ApiOperation({
    summary: 'Crear aporte',
    description: 'Crea un aporte para una meta específica',
  })
  @ApiResponse({
    status: 201,
    description: 'Aporte creado exitosamente',
    type: MetaResponseDto,
  })
  @ApiResponse({
    status: 404,
    description: 'Meta no encontrada',
  })
  @ApiBearerAuth()
  async createAporte(
    @Param('id', ParseIntPipe) id: number,
    @Body() createAporteDto: CreateAporteDto,
  ): Promise<MetaResponseDto> {
    // TODO: Extraer usuarioId del JWT
    const usuarioId = 1;
    return await this.metasService.createAporte(id, usuarioId, createAporteDto);
  }

  @Get(':id/aportes')
  @ApiOperation({
    summary: 'Obtener aportes de una meta',
    description: 'Obtiene todos los aportes realizados a una meta específica',
  })
  @ApiResponse({
    status: 200,
    description: 'Lista de aportes',
  })
  @ApiResponse({
    status: 404,
    description: 'Meta no encontrada',
  })
  @ApiBearerAuth()
  async findAportes(@Param('id', ParseIntPipe) id: number): Promise<any[]> {
    // TODO: Extraer usuarioId del JWT
    const usuarioId = 1;
    return await this.metasService.findAportesByMeta(id, usuarioId);
  }
}

