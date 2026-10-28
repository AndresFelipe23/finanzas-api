import {
  Injectable,
  UnauthorizedException,
  ConflictException,
  Logger,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { InjectConnection } from '@nestjs/typeorm';
import { Connection } from 'typeorm';
import * as bcrypt from 'bcrypt';
import { createHash, randomBytes } from 'crypto';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { MailService } from './mail.service';

const RESET_TTL_MS = 60 * 60 * 1000; // 1 hora

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);

  constructor(
    @InjectConnection()
    private readonly connection: Connection,
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
    private readonly mailService: MailService,
  ) {}

  /* ─────────────── Registro / Login ─────────────── */

  async register(registerDto: RegisterDto, userAgent?: string) {
    try {
      const existingUser = await this.connection.manager.query(
        'SELECT id FROM usuarios WHERE email = @0',
        [registerDto.email],
      );
      if (existingUser && existingUser.length > 0) {
        throw new ConflictException('El email ya está registrado');
      }

      const saltRounds = parseInt(this.configService.get<string>('BCRYPT_ROUNDS') || '10');
      const passwordHash = await bcrypt.hash(registerDto.password, saltRounds);
      const now = new Date();

      const insertQuery = `
        INSERT INTO usuarios (nombre, email, password_hash, telefono, fecha_nacimiento, moneda_predeterminada, activo, fecha_creacion, fecha_actualizacion)
        OUTPUT INSERTED.id, INSERTED.nombre, INSERTED.email, INSERTED.telefono, INSERTED.moneda_predeterminada
        VALUES (@0, @1, @2, @3, @4, @5, 1, @6, @6)
      `;
      const result = await this.connection.manager.query(insertQuery, [
        registerDto.nombre,
        registerDto.email,
        passwordHash,
        registerDto.telefono || null,
        registerDto.fechaNacimiento || null,
        registerDto.monedaPredeterminada || 'COP',
        now,
      ]);

      return await this.issueTokens(result[0], userAgent);
    } catch (error) {
      this.logger.error(`Error al registrar usuario: ${error.message}`);
      if (error instanceof ConflictException) throw error;
      throw new Error(`Error al registrar usuario: ${error.message}`);
    }
  }

  async login(loginDto: LoginDto, userAgent?: string) {
    try {
      const usuarios = await this.connection.manager.query(
        'SELECT * FROM usuarios WHERE email = @0 AND activo = 1',
        [loginDto.email],
      );
      if (!usuarios || usuarios.length === 0) {
        throw new UnauthorizedException('Credenciales inválidas');
      }

      const usuario = usuarios[0];
      const isPasswordValid = await bcrypt.compare(loginDto.password, usuario.password_hash);
      if (!isPasswordValid) {
        throw new UnauthorizedException('Credenciales inválidas');
      }

      return await this.issueTokens(usuario, userAgent);
    } catch (error) {
      this.logger.error(`Error al iniciar sesión: ${error.message}`);
      throw error;
    }
  }

  /* ─────────────── Tokens ─────────────── */

  /** Emite un access token JWT corto y un refresh token opaco (guardado en BD, revocable). */
  private async issueTokens(usuario: any, userAgent?: string) {
    const accessToken = this.generateAccessToken(usuario);
    const refreshToken = await this.createRefreshToken(usuario.id, userAgent);

    return {
      accessToken,
      refreshToken,
      user: this.mapUser(usuario),
    };
  }

  private generateAccessToken(usuario: any): string {
    return this.jwtService.sign({
      sub: usuario.id,
      email: usuario.email,
      nombre: usuario.nombre,
    });
  }

  private hashToken(raw: string): string {
    return createHash('sha256').update(raw).digest('hex');
  }

  private async createRefreshToken(usuarioId: number, userAgent?: string): Promise<string> {
    const raw = randomBytes(48).toString('hex');
    const days = parseInt(this.configService.get<string>('REFRESH_EXPIRES_DAYS') || '30', 10);
    const expira = new Date(Date.now() + days * 24 * 60 * 60 * 1000);

    await this.connection.manager.query(
      `INSERT INTO refresh_tokens (usuario_id, token_hash, expira, user_agent)
       VALUES (@0, @1, @2, @3)`,
      [usuarioId, this.hashToken(raw), expira, (userAgent || '').slice(0, 300) || null],
    );

    return raw;
  }

  /** Rota el refresh token: valida el actual, lo revoca y emite un par nuevo. */
  async refresh(rawRefresh: string, userAgent?: string) {
    const now = new Date();
    const rows = await this.connection.manager.query(
      `SELECT TOP 1 id, usuario_id FROM refresh_tokens
       WHERE token_hash = @0 AND revocado = 0 AND expira > @1`,
      [this.hashToken(rawRefresh), now],
    );

    if (!rows || rows.length === 0) {
      throw new UnauthorizedException('Sesión inválida o expirada');
    }

    const tokenRow = rows[0];
    const usuarios = await this.connection.manager.query(
      'SELECT * FROM usuarios WHERE id = @0 AND activo = 1',
      [tokenRow.usuario_id],
    );
    if (!usuarios || usuarios.length === 0) {
      throw new UnauthorizedException('Usuario no encontrado');
    }

    const nuevoRefresh = await this.createRefreshToken(tokenRow.usuario_id, userAgent);

    // Revocar el anterior y dejar rastro de rotación
    const nuevoRow = await this.connection.manager.query(
      'SELECT TOP 1 id FROM refresh_tokens WHERE token_hash = @0',
      [this.hashToken(nuevoRefresh)],
    );
    await this.connection.manager.query(
      'UPDATE refresh_tokens SET revocado = 1, reemplazado_por = @1 WHERE id = @0',
      [tokenRow.id, nuevoRow?.[0]?.id ?? null],
    );

    return {
      accessToken: this.generateAccessToken(usuarios[0]),
      refreshToken: nuevoRefresh,
      user: this.mapUser(usuarios[0]),
    };
  }

  /** Cierra una sesión concreta revocando su refresh token. Idempotente. */
  async logout(rawRefresh: string): Promise<{ message: string }> {
    if (rawRefresh) {
      await this.connection.manager.query(
        'UPDATE refresh_tokens SET revocado = 1 WHERE token_hash = @0 AND revocado = 0',
        [this.hashToken(rawRefresh)],
      );
    }
    return { message: 'Sesión cerrada' };
  }

  private async revokeAllRefreshTokens(usuarioId: number): Promise<void> {
    await this.connection.manager.query(
      'UPDATE refresh_tokens SET revocado = 1 WHERE usuario_id = @0 AND revocado = 0',
      [usuarioId],
    );
  }

  /* ─────────────── Recuperación de contraseña ─────────────── */

  /**
   * Genera un token de recuperación y envía el correo.
   * Responde SIEMPRE igual, exista o no el correo, para no revelar qué cuentas hay.
   */
  async forgotPassword(email: string): Promise<{ message: string }> {
    const respuestaGenerica = {
      message: 'Si el correo está registrado, te enviamos un enlace para restablecer tu contraseña.',
    };

    try {
      const usuarios = await this.connection.manager.query(
        'SELECT id, nombre, email FROM usuarios WHERE email = @0 AND activo = 1',
        [email],
      );
      if (!usuarios || usuarios.length === 0) {
        return respuestaGenerica;
      }

      const usuario = usuarios[0];

      // Invalidar solicitudes previas sin usar
      await this.connection.manager.query(
        'UPDATE password_reset_tokens SET usado = 1 WHERE usuario_id = @0 AND usado = 0',
        [usuario.id],
      );

      const raw = randomBytes(32).toString('hex');
      const expira = new Date(Date.now() + RESET_TTL_MS);
      await this.connection.manager.query(
        `INSERT INTO password_reset_tokens (usuario_id, token_hash, expira)
         VALUES (@0, @1, @2)`,
        [usuario.id, this.hashToken(raw), expira],
      );

      await this.mailService.sendPasswordReset(usuario.email, usuario.nombre, raw);
    } catch (error) {
      this.logger.error(`Error en forgotPassword: ${error.message}`);
      // Aun con error interno respondemos genérico para no filtrar información.
    }

    return respuestaGenerica;
  }

  /** Valida el token, cambia la contraseña y cierra todas las sesiones del usuario. */
  async resetPassword(rawToken: string, newPassword: string): Promise<{ message: string }> {
    const now = new Date();
    const rows = await this.connection.manager.query(
      `SELECT TOP 1 id, usuario_id FROM password_reset_tokens
       WHERE token_hash = @0 AND usado = 0 AND expira > @1`,
      [this.hashToken(rawToken), now],
    );

    if (!rows || rows.length === 0) {
      throw new BadRequestException('El enlace es inválido o ya expiró. Solicita uno nuevo.');
    }

    const tokenRow = rows[0];
    const saltRounds = parseInt(this.configService.get<string>('BCRYPT_ROUNDS') || '10');
    const passwordHash = await bcrypt.hash(newPassword, saltRounds);

    await this.connection.manager.query(
      'UPDATE usuarios SET password_hash = @1, fecha_actualizacion = @2 WHERE id = @0',
      [tokenRow.usuario_id, passwordHash, now],
    );
    await this.connection.manager.query(
      'UPDATE password_reset_tokens SET usado = 1 WHERE id = @0',
      [tokenRow.id],
    );

    // Cambiar la contraseña invalida todas las sesiones abiertas
    await this.revokeAllRefreshTokens(tokenRow.usuario_id);

    return { message: 'Tu contraseña se actualizó. Ya puedes iniciar sesión.' };
  }

  /* ─────────────── Perfil ─────────────── */

  async validateToken(token: string) {
    try {
      return this.jwtService.verify(token);
    } catch {
      return null;
    }
  }

  async getProfile(usuarioId: number) {
    try {
      const result = await this.connection.manager.query(
        'SELECT id, nombre, email, telefono, fecha_nacimiento, moneda_predeterminada FROM usuarios WHERE id = @0 AND activo = 1',
        [usuarioId],
      );
      if (!result || result.length === 0) {
        throw new NotFoundException('Usuario no encontrado');
      }
      const usuario = result[0];
      return {
        id: parseInt(usuario.id),
        nombre: usuario.nombre,
        email: usuario.email,
        telefono: usuario.telefono,
        fechaNacimiento: usuario.fecha_nacimiento
          ? new Date(usuario.fecha_nacimiento).toISOString()
          : null,
        monedaPredeterminada: usuario.moneda_predeterminada,
      };
    } catch (error) {
      this.logger.error(`Error al obtener perfil: ${error.message}`);
      if (error instanceof NotFoundException) throw error;
      throw new Error(`Error al obtener perfil: ${error.message}`);
    }
  }

  async updateProfile(usuarioId: number, updateProfileDto: UpdateProfileDto) {
    try {
      const usuarios = await this.connection.manager.query(
        'SELECT id FROM usuarios WHERE id = @0 AND activo = 1',
        [usuarioId],
      );
      if (!usuarios || usuarios.length === 0) {
        throw new NotFoundException('Usuario no encontrado');
      }

      const updateQuery = `
        EXEC sp_usuario_update_profile
          @UsuarioId = @0,
          @Nombre = @1,
          @Telefono = @2,
          @FechaNacimiento = @3,
          @MonedaPredeterminada = @4
      `;
      const result = await this.connection.manager.query(updateQuery, [
        usuarioId,
        updateProfileDto.nombre,
        updateProfileDto.telefono || null,
        updateProfileDto.fechaNacimiento || null,
        updateProfileDto.monedaPredeterminada || null,
      ]);

      const usuario = result[0];
      return {
        id: parseInt(usuario.id),
        nombre: usuario.nombre,
        email: usuario.email,
        telefono: usuario.telefono,
        fechaNacimiento: usuario.fecha_nacimiento
          ? new Date(usuario.fecha_nacimiento).toISOString()
          : null,
        monedaPredeterminada: usuario.moneda_predeterminada,
      };
    } catch (error) {
      this.logger.error(`Error al actualizar perfil: ${error.message}`);
      if (error instanceof NotFoundException) throw error;
      throw new Error(`Error al actualizar perfil: ${error.message}`);
    }
  }

  private mapUser(usuario: any) {
    return {
      id: parseInt(usuario.id),
      nombre: usuario.nombre,
      email: usuario.email,
      telefono: usuario.telefono,
      monedaPredeterminada: usuario.moneda_predeterminada,
    };
  }
}
