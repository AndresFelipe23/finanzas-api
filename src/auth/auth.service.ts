import { Injectable, UnauthorizedException, ConflictException, Inject, Logger } from '@nestjs/common';
import { InjectConnection } from '@nestjs/typeorm';
import { Connection } from 'typeorm';
import * as bcrypt from 'bcrypt';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);

  constructor(
    @InjectConnection()
    private readonly connection: Connection,
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
  ) {}

  /**
   * Registra un nuevo usuario
   */
  async register(registerDto: RegisterDto) {
    try {
      // Verificar si el email ya existe
      const existingUser = await this.connection.manager.query(
        'SELECT id FROM usuarios WHERE email = @0',
        [registerDto.email]
      );

      if (existingUser && existingUser.length > 0) {
        throw new ConflictException('El email ya está registrado');
      }

      // Encriptar la contraseña
      const saltRounds = parseInt(this.configService.get<string>('BCRYPT_ROUNDS') || '10');
      const passwordHash = await bcrypt.hash(registerDto.password, saltRounds);

      // Insertar el nuevo usuario usando parámetros posicionales
      const insertQuery = `
        INSERT INTO usuarios (nombre, email, password_hash, telefono, fecha_nacimiento, moneda_predeterminada, activo, fecha_creacion, fecha_actualizacion)
        OUTPUT INSERTED.id, INSERTED.nombre, INSERTED.email, INSERTED.telefono, INSERTED.moneda_predeterminada
        VALUES (@0, @1, @2, @3, @4, @5, 1, GETDATE(), GETDATE())
      `;

      const result = await this.connection.manager.query(insertQuery, [
        registerDto.nombre,
        registerDto.email,
        passwordHash,
        registerDto.telefono || null,
        registerDto.fechaNacimiento || null,
        registerDto.monedaPredeterminada || 'COP',
      ]);

      const usuario = result[0];

      // Generar token JWT
      const token = this.generateToken(usuario);

      return {
        accessToken: token,
        user: {
          id: parseInt(usuario.id),
          nombre: usuario.nombre,
          email: usuario.email,
          telefono: usuario.telefono,
          monedaPredeterminada: usuario.moneda_predeterminada,
        },
      };
    } catch (error) {
      this.logger.error(`Error al registrar usuario: ${error.message}`);
      
      if (error instanceof ConflictException) {
        throw error;
      }
      
      throw new Error(`Error al registrar usuario: ${error.message}`);
    }
  }

  /**
   * Inicia sesión usando el procedimiento almacenado sp_usuario_login
   */
  async login(loginDto: LoginDto) {
    try {
      // Buscar usuario por email
      const usuarios = await this.connection.manager.query(
        'SELECT * FROM usuarios WHERE email = @0 AND activo = 1',
        [loginDto.email]
      );

      if (!usuarios || usuarios.length === 0) {
        throw new UnauthorizedException('Credenciales inválidas');
      }

      const usuario = usuarios[0];

      // Verificar la contraseña
      const isPasswordValid = await bcrypt.compare(loginDto.password, usuario.password_hash);

      if (!isPasswordValid) {
        throw new UnauthorizedException('Credenciales inválidas');
      }

      // Generar token JWT
      const token = this.generateToken(usuario);

      return {
        accessToken: token,
        user: {
          id: parseInt(usuario.id),
          nombre: usuario.nombre,
          email: usuario.email,
          telefono: usuario.telefono,
          monedaPredeterminada: usuario.moneda_predeterminada,
        },
      };
    } catch (error) {
      this.logger.error(`Error al iniciar sesión: ${error.message}`);
      throw error;
    }
  }

  /**
   * Genera un token JWT para el usuario
   */
  private generateToken(usuario: any) {
    const payload = {
      sub: usuario.id,
      email: usuario.email,
      nombre: usuario.nombre,
    };

    return this.jwtService.sign(payload);
  }

  /**
   * Valida un token JWT
   */
  async validateToken(token: string) {
    try {
      const payload = this.jwtService.verify(token);
      return payload;
    } catch (error) {
      return null;
    }
  }
}

