import { Injectable, Module, OnModuleInit } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { ThrottlerModule } from '@nestjs/throttler';
import { InjectConnection, TypeOrmModule } from '@nestjs/typeorm';
import { Connection } from 'typeorm';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { AuthModule } from './auth/auth.module';
import { CategoriasModule } from './categorias/categorias.module';
import { CuentasModule } from './cuentas/cuentas.module';
import { TransaccionesModule } from './transacciones/transacciones.module';
import { PagosRecurrentesModule } from './pagos-recurrentes/pagos-recurrentes.module';
import { MetasModule } from './metas/metas.module';
import { Usuario } from './database/entities/usuario.entity';
import { Categoria } from './categorias/entities/categoria.entity';
import { Cuenta } from './cuentas/entities/cuenta.entity';
import { Transaccion } from './transacciones/entities/transaccion.entity';
import { PrestamosModule } from './prestamos/prestamos.module';
import { PresupuestosModule } from './presupuestos/presupuestos.module';
import { DashboardModule } from './dashboard/dashboard.module';
import { TarjetasNfcModule } from './tarjetas-nfc/tarjetas-nfc.module';
import { PagosNfcModule } from './pagos-nfc/pagos-nfc.module';
import { DispositivosNfcModule } from './dispositivos-nfc/dispositivos-nfc.module';

@Injectable()
export class AppServiceInit implements OnModuleInit {
  constructor(
    @InjectConnection()
    private readonly connection: Connection,
    private readonly configService: ConfigService,
  ) {}

  async onModuleInit() {
    try {
      await this.connection.query('SELECT 1');
      const host = this.configService.get<string>('DB_HOST');
      const database = this.configService.get<string>('DB_DATABASE');
      console.log('✅ Base de datos conectada correctamente');
      console.log(`📍 Host: ${host}`);
      console.log(`🗄️  Database: ${database}`);
    } catch (error) {
      console.error('❌ Error al conectar con la base de datos:', error.message);
    }
  }
}

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: '.env',
    }),
    // Registrado global; solo limita donde se aplica @UseGuards(ThrottlerGuard).
    ThrottlerModule.forRoot([{ ttl: 60000, limit: 100 }]),
    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],
      useFactory: (configService: ConfigService) => {
        const dbPort = configService.get<string>('DB_PORT');
        return {
          type: 'mssql',
          host: configService.get<string>('DB_HOST') || 'localhost',
          port: dbPort ? parseInt(dbPort, 10) : 1433,
          username: configService.get<string>('DB_USERNAME'),
          password: configService.get<string>('DB_PASSWORD'),
          database: configService.get<string>('DB_DATABASE'),
          entities: [Usuario, Categoria, Cuenta, Transaccion],
          synchronize: configService.get<string>('DB_SYNCHRONIZE') === 'true',
          logging: configService.get<string>('DB_LOGGING') === 'true',
          options: {
            encrypt: true,
            trustServerCertificate: true,
          },
        };
      },
      inject: [ConfigService],
    }),
    AuthModule,
    CategoriasModule,
    CuentasModule,
    TransaccionesModule,
    PagosRecurrentesModule,
    MetasModule,
    PrestamosModule,
    PresupuestosModule,
    DashboardModule,
    TarjetasNfcModule,
    PagosNfcModule,
    DispositivosNfcModule,
  ],
  controllers: [AppController],
  providers: [AppService, AppServiceInit],
})
export class AppModule {}
