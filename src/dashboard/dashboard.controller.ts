import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { DashboardService } from './dashboard.service';
import { DashboardResponseDto } from './dto/dashboard-response.dto';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUserId } from '../common/decorators/current-user.decorator';

@ApiTags('Dashboard')
@Controller('dashboard')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class DashboardController {
  constructor(private readonly dashboardService: DashboardService) {}

  @Get()
  @ApiOperation({
    summary: 'Obtener dashboard completo',
    description: 'Retorna resumen mensual, gastos/ingresos por categoría, evolución, presupuestos y metas',
  })
  @ApiQuery({ name: 'fecha', required: false, example: '2026-07', description: 'Mes en formato YYYY-MM' })
  @ApiResponse({ status: 200, type: DashboardResponseDto })
  async getDashboard(
    @CurrentUserId() usuarioId: number,
    @Query('fecha') fecha?: string,
  ): Promise<DashboardResponseDto> {
    return await this.dashboardService.getDashboard(usuarioId, fecha);
  }
}
