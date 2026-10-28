import {
  Controller,
  Post,
  Body,
  HttpCode,
  HttpStatus,
  UseGuards,
  Get,
  Request,
  Patch,
  Headers,
  UnauthorizedException,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';
import { Throttle, ThrottlerGuard } from '@nestjs/throttler';
import { AuthService } from './auth.service';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { ForgotPasswordDto } from './dto/forgot-password.dto';
import { ResetPasswordDto } from './dto/reset-password.dto';
import { RefreshTokenDto } from './dto/refresh-token.dto';
import { AuthResponseDto } from './dto/auth-response.dto';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';

@ApiTags('Autenticación')
@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('register')
  @ApiOperation({ summary: 'Registrar un nuevo usuario' })
  @ApiResponse({ status: 201, description: 'Usuario registrado', type: AuthResponseDto })
  @ApiResponse({ status: 409, description: 'El email ya está registrado' })
  @HttpCode(HttpStatus.CREATED)
  async register(
    @Body() registerDto: RegisterDto,
    @Headers('user-agent') userAgent?: string,
  ): Promise<AuthResponseDto> {
    return await this.authService.register(registerDto, userAgent);
  }

  @Post('login')
  @ApiOperation({ summary: 'Iniciar sesión' })
  @ApiResponse({ status: 200, description: 'Inicio de sesión exitoso', type: AuthResponseDto })
  @ApiResponse({ status: 401, description: 'Credenciales inválidas' })
  @HttpCode(HttpStatus.OK)
  async login(
    @Body() loginDto: LoginDto,
    @Headers('user-agent') userAgent?: string,
  ): Promise<AuthResponseDto> {
    return await this.authService.login(loginDto, userAgent);
  }

  @Post('refresh')
  @ApiOperation({
    summary: 'Renovar sesión',
    description: 'Emite un nuevo access token y rota el refresh token.',
  })
  @ApiResponse({ status: 200, description: 'Sesión renovada', type: AuthResponseDto })
  @ApiResponse({ status: 401, description: 'Sesión inválida o expirada' })
  @HttpCode(HttpStatus.OK)
  async refresh(
    @Body() dto: RefreshTokenDto,
    @Headers('user-agent') userAgent?: string,
  ): Promise<AuthResponseDto> {
    return await this.authService.refresh(dto.refreshToken, userAgent);
  }

  @Post('logout')
  @ApiOperation({ summary: 'Cerrar sesión', description: 'Revoca el refresh token indicado.' })
  @ApiResponse({ status: 200, description: 'Sesión cerrada' })
  @HttpCode(HttpStatus.OK)
  async logout(@Body() dto: RefreshTokenDto) {
    return await this.authService.logout(dto.refreshToken);
  }

  @Post('forgot-password')
  @UseGuards(ThrottlerGuard)
  @Throttle({ default: { limit: 3, ttl: 60000 } })
  @ApiOperation({
    summary: 'Solicitar recuperación de contraseña',
    description: 'Envía un enlace al correo si la cuenta existe. Responde siempre igual.',
  })
  @ApiResponse({ status: 200, description: 'Solicitud recibida' })
  @HttpCode(HttpStatus.OK)
  async forgotPassword(@Body() dto: ForgotPasswordDto) {
    return await this.authService.forgotPassword(dto.email);
  }

  @Post('reset-password')
  @UseGuards(ThrottlerGuard)
  @Throttle({ default: { limit: 5, ttl: 60000 } })
  @ApiOperation({ summary: 'Restablecer contraseña con un token de recuperación' })
  @ApiResponse({ status: 200, description: 'Contraseña actualizada' })
  @ApiResponse({ status: 400, description: 'Enlace inválido o expirado' })
  @HttpCode(HttpStatus.OK)
  async resetPassword(@Body() dto: ResetPasswordDto) {
    return await this.authService.resetPassword(dto.token, dto.password);
  }

  @Get('profile')
  @UseGuards(JwtAuthGuard)
  @ApiOperation({ summary: 'Obtener perfil' })
  @ApiBearerAuth()
  @ApiResponse({ status: 200, description: 'Perfil del usuario' })
  @ApiResponse({ status: 401, description: 'No autorizado' })
  async getProfile(@Request() req) {
    const usuarioId = req.user?.id;
    if (!usuarioId) throw new UnauthorizedException('Usuario no autenticado');
    return await this.authService.getProfile(usuarioId);
  }

  @Patch('profile')
  @UseGuards(JwtAuthGuard)
  @ApiOperation({ summary: 'Actualizar perfil' })
  @ApiBearerAuth()
  @ApiResponse({ status: 200, description: 'Perfil actualizado' })
  @ApiResponse({ status: 401, description: 'No autorizado' })
  @HttpCode(HttpStatus.OK)
  async updateProfile(@Request() req, @Body() updateProfileDto: UpdateProfileDto) {
    const usuarioId = req.user?.id;
    if (!usuarioId) throw new UnauthorizedException('Usuario no autenticado');
    return await this.authService.updateProfile(usuarioId, updateProfileDto);
  }
}
