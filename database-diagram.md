# 📊 Diagrama de Relaciones - Base de Datos Sistema de Finanzas

## Estructura de Tablas y Relaciones

### 🔵 Entidades Principales

#### **1. usuarios**
- **Propósito**: Información de los usuarios del sistema
- **Tipos de fecha**: Todos los campos de fecha usan DATETIME2 para mayor precisión
- **Relaciones**:
  - → `cuentas` (1:N)
  - → `transacciones` (1:N)
  - → `categorias` (1:N)
  - → `presupuestos` (1:N)
  - → `metas` (1:N)
  - → `prestamos` (1:N)
  - → `pagos_recurrentes` (1:N)
  - → `tarjetas_nfc` (1:N)
  - → `dispositivos_nfc` (1:N)
  - → `pagos_nfc` (1:N)

#### **2. cuentas**
- **Propósito**: Cuentas bancarias, efectivo, wallets del usuario
- **Tipos**: BANCARIA, EFECTIVO, TARJETA_CREDITO, TARJETA_DEBITO, DIGITAL, AHORRO, INVERSION
- **Relaciones**:
  - ← `usuarios` (N:1)
  - → `transacciones` (1:N)
  - → `tarjetas_nfc` (1:N)
  - → `aportes_metas` (1:N)
  - → `pagos_prestamos` (1:N)

#### **3. transacciones**
- **Propósito**: Registro de todas las operaciones financieras
- **Relaciones**:
  - ← `usuarios` (N:1)
  - ← `cuentas` (N:1, nullable)
  - ← `tipos_transaccion` (N:1)
  - ← `categorias` (N:1, nullable)
  - ← `metodos_pago` (N:1, nullable)
  - → `pagos_nfc` (1:1)

#### **4. tipos_transaccion**
- **Propósito**: Define el tipo de movimiento (INGRESO, GASTO, TRANSFERENCIA)
- **Relaciones**:
  - → `transacciones` (1:N)

#### **5. categorias**
- **Propósito**: Categorías personalizadas o globales para clasificar transacciones
- **Relaciones**:
  - ← `usuarios` (N:1, nullable para globales)
  - → `transacciones` (1:N)
  - → `presupuestos` (1:N)
  - → `pagos_recurrentes` (1:N)

#### **6. metodos_pago**
- **Propósito**: Formas de pago (efectivo, tarjeta, transferencia, etc.)
- **Relaciones**:
  - → `transacciones` (1:N)
  - → `pagos_recurrentes` (1:N)

---

### 🟢 Sistema de Presupuestos

#### **7. presupuestos**
- **Propósito**: Presupuestos mensuales por categoría
- **Campos especiales**:
  - `monto_presupuesto`: Presupuesto asignado
  - `monto_gastado`: Calculado por transacciones reales
  - `periodo`: YYYY-MM-01
- **Relaciones**:
  - ← `usuarios` (N:1)
  - ← `categorias` (N:1)

---

### 🟡 Sistema de Metas

#### **8. metas**
- **Propósito**: Objetivos financieros del usuario
- **Relaciones**:
  - ← `usuarios` (N:1)
  - → `aportes_metas` (1:N)

#### **9. aportes_metas**
- **Propósito**: Historial de aportes a metas
- **Relaciones**:
  - ← `metas` (N:1)
  - ← `cuentas` (N:1, nullable)

---

### 🔴 Sistema de Préstamos

#### **10. prestamos**
- **Propósito**: Préstamos que el usuario debe o le deben
- **Campos especiales**:
  - `tipo`: DEBO / ME_DEBEN
  - `monto_pendiente`: Calculado automáticamente (monto_total - monto_pagado)
- **Relaciones**:
  - ← `usuarios` (N:1)
  - → `pagos_prestamos` (1:N)

#### **11. pagos_prestamos**
- **Propósito**: Historial de pagos de préstamos
- **Relaciones**:
  - ← `prestamos` (N:1)
  - ← `cuentas` (N:1, nullable)

---

### 💳 Sistema de Pagos Recurrentes

#### **12. pagos_recurrentes**
- **Propósito**: Configuración de pagos automáticos recurrentes
- **Frecuencias**: DIARIO, SEMANAL, MENSUAL, BIMESTRAL, TRIMESTRAL, SEMESTRAL, ANUAL
- **Relaciones**:
  - ← `usuarios` (N:1)
  - ← `categorias` (N:1)
  - ← `cuentas` (N:1, nullable)
  - ← `metodos_pago` (N:1, nullable)

---

### 📱 Sistema NFC

#### **13. tarjetas_nfc**
- **Propósito**: Tarjetas registradas para pagos por NFC
- **Relaciones**:
  - ← `usuarios` (N:1)
  - ← `cuentas` (N:1, nullable)
  - → `pagos_nfc` (1:N)

#### **14. dispositivos_nfc**
- **Propósito**: Dispositivos que emiten NFC (teléfonos, smartwatches)
- **Relaciones**:
  - ← `usuarios` (N:1)
  - → `pagos_nfc` (1:N)

#### **15. pagos_nfc**
- **Propósito**: Registro de pagos realizados por NFC
- **Campos especiales**:
  - `ubicacion`: Geocodificación del lugar
  - `latitud`, `longitud`: Coordenadas GPS
- **Relaciones**:
  - ← `usuarios` (N:1)
  - ← `tarjetas_nfc` (N:1)
  - ← `transacciones` (N:1)
  - ← `dispositivos_nfc` (N:1)

---

## 📋 Resumen de Relaciones

```
usuarios
├── cuentas (1:N)
│   ├── transacciones
│   ├── tarjetas_nfc
│   ├── aportes_metas
│   └── pagos_prestamos
├── transacciones (1:N)
├── categorias (1:N)
├── presupuestos (1:N)
├── metas (1:N)
│   └── aportes_metas
├── prestamos (1:N)
│   └── pagos_prestamos
├── pagos_recurrentes (1:N)
├── tarjetas_nfc (1:N)
│   └── pagos_nfc
├── dispositivos_nfc (1:N)
│   └── pagos_nfc
└── pagos_nfc (1:N)

tipos_transaccion → transacciones
metodos_pago → transacciones, pagos_recurrentes
```

---

## 🎯 Características del Diseño

### 📅 Campos de Fecha con DATETIME2

Todos los campos de fecha en la base de datos utilizan el tipo **DATETIME2** para:
- **Mayor precisión temporal**: Hasta microsegundos
- **Rango extendido**: Del año 0001 al 9999
- **Mejor control**: Incluye hora, minutos, segundos y fracciones
- **Compatibilidad**: Mejor integración con aplicaciones modernas

**Campos actualizados:**
- `usuarios.fecha_nacimiento`
- `pagos_recurrentes.fecha_inicio` y `fecha_fin`
- `presupuestos.periodo`
- `metas.fecha_objetivo`
- `prestamos.fecha_prestamo` y `fecha_vencimiento`
- `transacciones.fecha_transaccion`
- Todos los campos `fecha_creacion`, `fecha_actualizacion`, `fecha_pago`, etc.

### ✅ Ventajas del Diseño

1. **Normalización**: Tablas bien normalizadas, sin redundancia
2. **Integridad Referencial**: Foreign keys con CASCADE/SET NULL según corresponde
3. **Flexibilidad**: Soporte para múltiples monedas por cuenta
4. **Escalabilidad**: Índices en campos de búsqueda frecuente
5. **Auditoría**: Campos de fecha_creacion, fecha_actualizacion en tablas principales
6. **Blanqueabilidad**: Campos activo/activa para soft deletes
7. **Geolocalización**: Coordenadas GPS para pagos NFC
8. **Cálculos Automáticos**: Columnas PERSISTED para montos pendientes
9. **Triggers**: Actualización automática de fechas
10. **Vistas**: Consultas pre-optimizadas para reportes comunes

### 🔐 Consideraciones de Seguridad

- **Contraseñas**: Campo `password_hash` para almacenar hashes
- **Tarjetas**: `numero_tarjeta_hash` para guardar solo últimos 4 dígitos hasheados
- **Auditoría**: Todas las tablas críticas tienen campos de auditoría

### 📊 Datos Iniciales

El script incluye datos de ejemplo para:
- Tipos de transacción (3 tipos)
- Métodos de pago (8 métodos comunes)
- Categorías globales (13 categorías estándar)

---

## 🚀 Próximos Pasos

Para implementar en NestJS:
1. Configurar TypeORM o Prisma
2. Crear entidades/modelos
3. Configurar módulos por dominio
4. Implementar servicios y controladores
5. Agregar autenticación JWT
6. Configurar DTOs para validación
