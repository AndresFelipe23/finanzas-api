# 🏗️ Estructura del Proyecto - API de Finanzas

## 📁 Organización de Carpetas

```
src/
├── auth/                     # 🔐 Autenticación y autorización
│   ├── auth.controller.ts
│   ├── auth.service.ts
│   ├── auth.module.ts
│   ├── dto/
│   │   ├── login.dto.ts
│   │   └── register.dto.ts
│   └── strategies/
│       └── jwt.strategy.ts
│
├── usuarios/                 # 👤 Gestión de usuarios
│   ├── usuarios.controller.ts
│   ├── usuarios.service.ts
│   ├── usuarios.module.ts
│   └── dto/
│       ├── create-usuario.dto.ts
│       └── update-usuario.dto.ts
│
├── categorias/               # 📂 Categorías de gastos/ingresos
│   ├── categorias.controller.ts
│   ├── categorias.service.ts
│   ├── categorias.module.ts
│   └── dto/
│       ├── create-categoria.dto.ts
│       └── update-categoria.dto.ts
│
├── cuentas/                  # 💳 Cuentas bancarias y financieras
│   ├── cuentas.controller.ts
│   ├── cuentas.service.ts
│   ├── cuentas.module.ts
│   └── dto/
│       ├── create-cuenta.dto.ts
│       └── update-cuenta.dto.ts
│
├── transacciones/            # 💰 Transacciones financieras
│   ├── transacciones.controller.ts
│   ├── transacciones.service.ts
│   ├── transacciones.module.ts
│   └── dto/
│       ├── create-transaccion.dto.ts
│       └── update-transaccion.dto.ts
│
├── metodos-pago/             # 💳 Métodos de pago
│   ├── metodos-pago.controller.ts
│   ├── metodos-pago.service.ts
│   └── metodos-pago.module.ts
│
├── tarjetas-nfc/             # 🎴 Tarjetas NFC
│   ├── tarjetas-nfc.controller.ts
│   ├── tarjetas-nfc.service.ts
│   ├── tarjetas-nfc.module.ts
│   └── dto/
│       └── create-tarjeta-nfc.dto.ts
│
├── dispositivos-nfc/         # 📱 Dispositivos NFC
│   ├── dispositivos-nfc.controller.ts
│   ├── dispositivos-nfc.service.ts
│   └── dispositivos-nfc.module.ts
│
├── pagos-recurrentes/        # 🔄 Pagos recurrentes
│   ├── pagos-recurrentes.controller.ts
│   ├── pagos-recurrentes.service.ts
│   ├── pagos-recurrentes.module.ts
│   └── dto/
│       ├── create-pago-recurrente.dto.ts
│       └── update-pago-recurrente.dto.ts
│
├── presupuestos/             # 📊 Presupuestos
│   ├── presupuestos.controller.ts
│   ├── presupuestos.service.ts
│   ├── presupuestos.module.ts
│   └── dto/
│       ├── create-presupuesto.dto.ts
│       └── update-presupuesto.dto.ts
│
├── metas/                    # 🎯 Metas financieras
│   ├── metas.controller.ts
│   ├── metas.service.ts
│   ├── metas.module.ts
│   └── dto/
│       ├── create-meta.dto.ts
│       ├── update-meta.dto.ts
│       └── aporte-meta.dto.ts
│
├── prestamos/                # 💵 Préstamos
│   ├── prestamos.controller.ts
│   ├── prestamos.service.ts
│   ├── prestamos.module.ts
│   └── dto/
│       ├── create-prestamo.dto.ts
│       ├── update-prestamo.dto.ts
│       └── pago-prestamo.dto.ts
│
├── pagos-nfc/                # 📲 Pagos mediante NFC
│   ├── pagos-nfc.controller.ts
│   ├── pagos-nfc.service.ts
│   └── pagos-nfc.module.ts
│
├── common/                   # 🛠️ Utilidades y componentes compartidos
│   ├── guards/
│   │   ├── jwt-auth.guard.ts
│   │   └── roles.guard.ts
│   ├── interceptors/
│   │   ├── logging.interceptor.ts
│   │   └── transform.interceptor.ts
│   ├── decorators/
│   │   ├── current-user.decorator.ts
│   │   └── roles.decorator.ts
│   ├── pipes/
│   │   ├── validation.pipe.ts
│   │   └── parse-int.pipe.ts
│   ├── filters/
│   │   └── http-exception.filter.ts
│   └── dto/
│       └── pagination.dto.ts
│
├── config/                   # ⚙️ Configuraciones
│   ├── typeorm.config.ts
│   └── app.config.ts
│
├── database/                 # 🗄️ Configuración de base de datos
│   ├── entities/             # Entidades TypeORM
│   │   ├── usuario.entity.ts
│   │   ├── categoria.entity.ts
│   │   ├── cuenta.entity.ts
│   │   ├── transaccion.entity.ts
│   │   ├── metodo-pago.entity.ts
│   │   ├── tarjeta-nfc.entity.ts
│   │   ├── dispositivo-nfc.entity.ts
│   │   ├── pago-recurrente.entity.ts
│   │   ├── presupuesto.entity.ts
│   │   ├── meta.entity.ts
│   │   ├── prestamo.entity.ts
│   │   └── pago-nfc.entity.ts
│   └── migrations/            # Migraciones de base de datos
│       └── migrations.ts
│
├── app.module.ts             # 📦 Módulo principal
├── app.controller.ts         # 🎛️ Controlador principal
├── app.service.ts            # 🔧 Servicio principal
└── main.ts                   # 🚀 Punto de entrada
```

## 📋 Descripción de Carpetas

### 🔐 auth/
Módulo de autenticación y autorización (JWT, login, registro, recuperación de contraseña).

### 📊 Módulos de Negocio
- **usuarios/**: Gestión de usuarios del sistema
- **categorias/**: Categorías de ingresos y gastos
- **cuentas/**: Cuentas bancarias, efectivo, wallets
- **transacciones/**: Transacciones financieras (ingresos, gastos, transferencias)
- **metodos-pago/**: Métodos de pago (efectivo, tarjeta, transferencia)
- **tarjetas-nfc/**: Tarjetas NFC registradas
- **dispositivos-nfc/**: Dispositivos NFC (teléfonos, smartwatches)
- **pagos-recurrentes/**: Configuración de pagos recurrentes
- **presupuestos/**: Presupuestos mensuales por categoría
- **metas/**: Metas financieras de ahorro
- **prestamos/**: Préstamos (debo/me deben)
- **pagos-nfc/**: Historial de pagos NFC

### 🛠️ common/
Componentes compartidos para toda la aplicación:
- **guards/**: Guardias de autenticación/autorización
- **interceptors/**: Interceptores (logging, transformación)
- **decorators/**: Decoradores personalizados
- **pipes/**: Pipes de validación y transformación
- **filters/**: Filtros de excepciones
- **dto/**: DTOs compartidos (paginación, etc.)

### ⚙️ config/
Configuraciones de la aplicación (TypeORM, app config).

### 🗄️ database/
- **entities/**: Entidades TypeORM correspondientes a cada tabla
- **migrations/**: Migraciones de base de datos

## 🎯 Próximos Pasos

1. Crear las entidades en `database/entities/`
2. Crear los módulos con su estructura estándar (controller, service, module, DTOs)
3. Configurar los módulos en `app.module.ts`
4. Implementar autenticación JWT
5. Crear guards y decoradores para seguridad

## 📝 Convenciones

- Cada módulo tiene su propia carpeta
- Cada módulo contiene: `{module}.controller.ts`, `{module}.service.ts`, `{module}.module.ts`
- Los DTOs van en subcarpeta `dto/` dentro del módulo
- Las entidades van en `database/entities/`
- Los componentes compartidos van en `common/`

