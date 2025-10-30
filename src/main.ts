import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // Habilitar CORS para Flutter
  app.enableCors({
    origin: true, // Permitir todas las orígenes en desarrollo
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE',
    credentials: true,
  });

  // Global prefix para todas las rutas
  app.setGlobalPrefix('api');

  // Validación global de DTOs
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true, // Eliminar propiedades no definidas en el DTO
      forbidNonWhitelisted: true, // Lanzar error si hay propiedades no permitidas
      transform: true, // Transformar automáticamente los tipos
      transformOptions: {
        enableImplicitConversion: true,
      },
    }),
  );

  // Configuración de Swagger
  const config = new DocumentBuilder()
    .setTitle('API de Finanzas')
    .setDescription('API REST para gestión de finanzas personales')
    .setVersion('1.0')
    .addBearerAuth()
    .addTag('Autenticación', 'Endpoints de autenticación y registro')
    .build();

  const document = SwaggerModule.createDocument(app, config);
  
  // JSON de OpenAPI para Scalar
  app.getHttpAdapter().getInstance().get('/openapi.json', (req, res) => {
    res.json(document);
  });
  
  // HTML de Scalar
  const scalarHtml = `
  <!DOCTYPE html>
  <html>
    <head>
      <title>API de Finanzas</title>
      <meta charset="utf-8" />
      <meta name="viewport" content="width=device-width, initial-scale=1" />
    </head>
    <body>
      <script
        id="api-reference"
        data-url="/openapi.json"
        type="application/json"
      ></script>
      <script src="https://cdn.jsdelivr.net/npm/@scalar/api-reference"></script>
    </body>
  </html>
  `;
  
  app.getHttpAdapter().getInstance().get('/scalar', (req, res) => {
    res.send(scalarHtml);
  });

  // Redirección de la raíz a Scalar
  app.getHttpAdapter().getInstance().get('/', (req, res) => {
    res.redirect('/scalar');
  });

  // Swagger UI (backup)
  SwaggerModule.setup('api/docs', app, document);
  
  const port = process.env.PORT || 3001;
  await app.listen(port);
  
  console.log(`🚀 Servidor corriendo en: http://localhost:${port}`);
  console.log(`✨ Documentación Scalar: http://localhost:${port}/scalar`);
  console.log(`📚 Documentación Swagger: http://localhost:${port}/api/docs`);
}

bootstrap();
