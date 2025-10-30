-- =====================================================
-- ESQUEMA DE BASE DE DATOS PARA SISTEMA DE FINANZAS
-- SQL Server Database Schema
-- =====================================================

CREATE DATABASE FinanzasApiApp
GO

USE FinanzasApiApp
GO

-- Tabla: Usuarios
-- Almacena información de los usuarios del sistema
CREATE TABLE usuarios (
    id BIGINT IDENTITY(1,1) PRIMARY KEY,
    nombre NVARCHAR(100) NOT NULL,
    email NVARCHAR(255) NOT NULL UNIQUE,
    password_hash NVARCHAR(255) NOT NULL,
    telefono NVARCHAR(20) NULL,
    fecha_nacimiento DATETIME2 NULL,
    moneda_predeterminada NVARCHAR(10) DEFAULT 'COP' NOT NULL,
    activo BIT DEFAULT 1 NOT NULL,
    fecha_creacion DATETIME2 DEFAULT GETDATE() NOT NULL,
    fecha_actualizacion DATETIME2 DEFAULT GETDATE() NOT NULL
);
GO

-- Tabla: Categorías
-- Categorías de gastos e ingresos (creadas por usuario o generales)
CREATE TABLE categorias (
    id BIGINT IDENTITY(1,1) PRIMARY KEY,
    usuario_id BIGINT NULL, -- NULL para categorías globales del sistema
    nombre NVARCHAR(100) NOT NULL,
    icono NVARCHAR(50) NULL,
    color NVARCHAR(7) NULL,
    tipo NVARCHAR(20) NOT NULL CHECK (tipo IN ('INGRESO', 'GASTO', 'AMBOS')),
    activo BIT DEFAULT 1 NOT NULL,
    fecha_creacion DATETIME2 DEFAULT GETDATE() NOT NULL,
    CONSTRAINT FK_categorias_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE,
    CONSTRAINT UQ_categorias_usuario_nombre UNIQUE (usuario_id, nombre)
);
GO

-- Tabla: Métodos de Pago
-- Efectivo, tarjeta de crédito, débito, transferencia, etc.
CREATE TABLE metodos_pago (
    id BIGINT IDENTITY(1,1) PRIMARY KEY,
    nombre NVARCHAR(50) NOT NULL,
    icono NVARCHAR(50) NULL,
    tipo NVARCHAR(20) NOT NULL CHECK (tipo IN ('EFECTIVO', 'TARJETA', 'TRANSFERENCIA', 'DIGITAL', 'OTRO')),
    activo BIT DEFAULT 1 NOT NULL
);
GO

-- Tabla: Cuentas
-- Cuentas bancarias, efectivo, wallets digitales del usuario
CREATE TABLE cuentas (
    id BIGINT IDENTITY(1,1) PRIMARY KEY,
    usuario_id BIGINT NOT NULL,
    nombre NVARCHAR(100) NOT NULL,
    tipo NVARCHAR(30) NOT NULL CHECK (tipo IN ('BANCARIA', 'EFECTIVO', 'TARJETA_CREDITO', 'TARJETA_DEBITO', 'DIGITAL', 'AHORRO', 'INVERSION')),
    moneda NVARCHAR(10) DEFAULT 'COP' NOT NULL,
    saldo_inicial DECIMAL(18,2) DEFAULT 0 NOT NULL,
    color NVARCHAR(7) NULL,
    icono NVARCHAR(50) NULL,
    descripcion NVARCHAR(500) NULL,
    activa BIT DEFAULT 1 NOT NULL,
    fecha_creacion DATETIME2 DEFAULT GETDATE() NOT NULL,
    CONSTRAINT FK_cuentas_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE
);
GO

-- Tabla: Tarjetas NFC
-- Tarjetas de débito/crédito registradas para pagos por NFC
CREATE TABLE tarjetas_nfc (
    id BIGINT IDENTITY(1,1) PRIMARY KEY,
    usuario_id BIGINT NOT NULL,
    cuenta_id BIGINT NULL, -- Relacionada con la cuenta de donde se deduce
    nombre_portador NVARCHAR(100) NOT NULL,
    numero_tarjeta_hash NVARCHAR(100) NOT NULL, -- Últimos 4 dígitos hasheados
    tipo NVARCHAR(20) NOT NULL CHECK (tipo IN ('DEBITO', 'CREDITO')),
    banco NVARCHAR(100) NULL,
    color NVARCHAR(7) NULL,
    activa BIT DEFAULT 1 NOT NULL,
    fecha_creacion DATETIME2 DEFAULT GETDATE() NOT NULL,
    CONSTRAINT FK_tarjetas_nfc_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE,
    CONSTRAINT FK_tarjetas_nfc_cuenta FOREIGN KEY (cuenta_id) REFERENCES cuentas(id) ON DELETE NO ACTION
);
GO

-- Tabla: Dispositivos NFC
-- Dispositivos que pueden emitir NFC (teléfonos, smartwatches, etc.)
CREATE TABLE dispositivos_nfc (
    id BIGINT IDENTITY(1,1) PRIMARY KEY,
    usuario_id BIGINT NOT NULL,
    nombre NVARCHAR(100) NOT NULL,
    tipo_dispositivo NVARCHAR(50) NOT NULL CHECK (tipo_dispositivo IN ('TELEFONO', 'SMARTWATCH', 'TAG', 'PULSERA', 'OTRO')),
    identificador_unico NVARCHAR(100) NOT NULL UNIQUE,
    activo BIT DEFAULT 1 NOT NULL,
    fecha_registro DATETIME2 DEFAULT GETDATE() NOT NULL,
    CONSTRAINT FK_dispositivos_nfc_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE
);
GO

-- Tabla: Tipos de Transacción
-- Ingreso, Gasto, Transferencia
CREATE TABLE tipos_transaccion (
    id BIGINT IDENTITY(1,1) PRIMARY KEY,
    nombre NVARCHAR(30) NOT NULL UNIQUE,
    descripcion NVARCHAR(200) NULL,
    activo BIT DEFAULT 1 NOT NULL
);
GO

-- Tabla: Transacciones
-- Todas las transacciones financieras del usuario
CREATE TABLE transacciones (
    id BIGINT IDENTITY(1,1) PRIMARY KEY,
    usuario_id BIGINT NOT NULL,
    cuenta_id BIGINT NULL, -- NULL para transferencias
    tipo_transaccion_id BIGINT NOT NULL,
    categoria_id BIGINT NULL, -- NULL para transferencias
    metodo_pago_id BIGINT NULL,
    monto DECIMAL(18,2) NOT NULL,
    moneda NVARCHAR(10) DEFAULT 'COP' NOT NULL,
    titulo NVARCHAR(150) NULL,
    descripcion NVARCHAR(500) NULL,
    fecha_transaccion DATETIME2 NOT NULL,
    archivo_adjunto NVARCHAR(500) NULL, -- URL o path de recibo/boleta
    notas NVARCHAR(1000) NULL,
    repetir BIT DEFAULT 0 NOT NULL,
    activa BIT DEFAULT 1 NOT NULL,
    fecha_creacion DATETIME2 DEFAULT GETDATE() NOT NULL,
    CONSTRAINT FK_transacciones_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE,
    CONSTRAINT FK_transacciones_cuenta FOREIGN KEY (cuenta_id) REFERENCES cuentas(id) ON DELETE NO ACTION,
    CONSTRAINT FK_transacciones_tipo FOREIGN KEY (tipo_transaccion_id) REFERENCES tipos_transaccion(id),
    CONSTRAINT FK_transacciones_categoria FOREIGN KEY (categoria_id) REFERENCES categorias(id) ON DELETE NO ACTION,
    CONSTRAINT FK_transacciones_metodo_pago FOREIGN KEY (metodo_pago_id) REFERENCES metodos_pago(id) ON DELETE SET NULL
);
GO

-- Tabla: Pagos Recurrentes
-- Configuración de pagos que se repiten automáticamente
CREATE TABLE pagos_recurrentes (
    id BIGINT IDENTITY(1,1) PRIMARY KEY,
    usuario_id BIGINT NOT NULL,
    categoria_id BIGINT NOT NULL,
    cuenta_id BIGINT NULL,
    metodo_pago_id BIGINT NULL,
    monto DECIMAL(18,2) NOT NULL,
    descripcion NVARCHAR(500) NOT NULL,
    frecuencia NVARCHAR(20) NOT NULL CHECK (frecuencia IN ('DIARIO', 'SEMANAL', 'MENSUAL', 'BIMESTRAL', 'TRIMESTRAL', 'SEMESTRAL', 'ANUAL')),
    dia_vencimiento INT NULL, -- Día del mes (1-31)
    dia_semana INT NULL, -- Día de la semana (1=Lunes, 7=Domingo)
    fecha_inicio DATETIME2 NOT NULL,
    fecha_fin DATETIME2 NULL,
    activo BIT DEFAULT 1 NOT NULL,
    fecha_creacion DATETIME2 DEFAULT GETDATE() NOT NULL,
    CONSTRAINT FK_pagos_recurrentes_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE,
    CONSTRAINT FK_pagos_recurrentes_categoria FOREIGN KEY (categoria_id) REFERENCES categorias(id) ON DELETE NO ACTION,
    CONSTRAINT FK_pagos_recurrentes_cuenta FOREIGN KEY (cuenta_id) REFERENCES cuentas(id) ON DELETE NO ACTION,
    CONSTRAINT FK_pagos_recurrentes_metodo_pago FOREIGN KEY (metodo_pago_id) REFERENCES metodos_pago(id) ON DELETE SET NULL
);
GO

-- Tabla: Pagos NFC
-- Registro de pagos realizados mediante tecnología NFC
CREATE TABLE pagos_nfc (
    id BIGINT IDENTITY(1,1) PRIMARY KEY,
    usuario_id BIGINT NOT NULL,
    tarjeta_nfc_id BIGINT NOT NULL,
    transaccion_id BIGINT NOT NULL,
    dispositivo_nfc_id BIGINT NOT NULL,
    ubicacion NVARCHAR(200) NULL, -- Geocodificación del lugar del pago
    latitud DECIMAL(10,8) NULL,
    longitud DECIMAL(11,8) NULL,
    fecha_pago DATETIME2 DEFAULT GETDATE() NOT NULL,
    CONSTRAINT FK_pagos_nfc_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE,
    CONSTRAINT FK_pagos_nfc_tarjeta FOREIGN KEY (tarjeta_nfc_id) REFERENCES tarjetas_nfc(id) ON DELETE NO ACTION,
    CONSTRAINT FK_pagos_nfc_transaccion FOREIGN KEY (transaccion_id) REFERENCES transacciones(id) ON DELETE NO ACTION,
    CONSTRAINT FK_pagos_nfc_dispositivo FOREIGN KEY (dispositivo_nfc_id) REFERENCES dispositivos_nfc(id) ON DELETE NO ACTION
);
GO

-- Tabla: Presupuestos
-- Presupuestos mensuales por categoría
CREATE TABLE presupuestos (
    id BIGINT IDENTITY(1,1) PRIMARY KEY,
    usuario_id BIGINT NOT NULL,
    categoria_id BIGINT NOT NULL,
    monto_presupuesto DECIMAL(18,2) NOT NULL,
    monto_gastado DECIMAL(18,2) DEFAULT 0 NOT NULL,
    periodo DATETIME2 NOT NULL, -- Primer día/hora del mes (YYYY-MM-01 00:00:00)
    activo BIT DEFAULT 1 NOT NULL,
    fecha_creacion DATETIME2 DEFAULT GETDATE() NOT NULL,
    fecha_actualizacion DATETIME2 DEFAULT GETDATE() NOT NULL,
    CONSTRAINT FK_presupuestos_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE,
    CONSTRAINT FK_presupuestos_categoria FOREIGN KEY (categoria_id) REFERENCES categorias(id) ON DELETE NO ACTION,
    CONSTRAINT UQ_presupuestos_usuario_categoria_periodo UNIQUE (usuario_id, categoria_id, periodo)
);
GO

-- Tabla: Metas
-- Metas financieras del usuario (ahorro, compra, etc.)
CREATE TABLE metas (
    id BIGINT IDENTITY(1,1) PRIMARY KEY,
    usuario_id BIGINT NOT NULL,
    nombre NVARCHAR(200) NOT NULL,
    descripcion NVARCHAR(1000) NULL,
    monto_objetivo DECIMAL(18,2) NOT NULL,
    monto_actual DECIMAL(18,2) DEFAULT 0 NOT NULL,
    fecha_objetivo DATETIME2 NOT NULL,
    icono NVARCHAR(50) NULL,
    color NVARCHAR(7) NULL,
    activa BIT DEFAULT 1 NOT NULL,
    fecha_creacion DATETIME2 DEFAULT GETDATE() NOT NULL,
    fecha_actualizacion DATETIME2 DEFAULT GETDATE() NOT NULL,
    CONSTRAINT FK_metas_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE
);
GO

-- Tabla: Aportes de Metas
-- Historial de aportes realizados a las metas
CREATE TABLE aportes_metas (
    id BIGINT IDENTITY(1,1) PRIMARY KEY,
    meta_id BIGINT NOT NULL,
    cuenta_id BIGINT NULL, -- Cuenta desde donde se hizo el aporte
    monto_aporte DECIMAL(18,2) NOT NULL,
    fecha_aporte DATETIME2 DEFAULT GETDATE() NOT NULL,
    notas NVARCHAR(500) NULL,
    CONSTRAINT FK_aportes_metas FOREIGN KEY (meta_id) REFERENCES metas(id) ON DELETE CASCADE,
    CONSTRAINT FK_aportes_metas_cuenta FOREIGN KEY (cuenta_id) REFERENCES cuentas(id) ON DELETE NO ACTION
);
GO

-- Tabla: Préstamos
-- Préstamos que el usuario debe o ha prestado a otros
CREATE TABLE prestamos (
    id BIGINT IDENTITY(1,1) PRIMARY KEY,
    usuario_id BIGINT NOT NULL,
    tipo NVARCHAR(20) NOT NULL CHECK (tipo IN ('DEBO', 'ME_DEBEN')),
    nombre_deudor_prestador NVARCHAR(100) NOT NULL, -- Nombre de quien debe/presta
    monto_total DECIMAL(18,2) NOT NULL,
    monto_pagado DECIMAL(18,2) DEFAULT 0 NOT NULL,
    monto_pendiente AS (monto_total - monto_pagado) PERSISTED, -- Calculado automáticamente
    fecha_prestamo DATETIME2 NOT NULL,
    fecha_vencimiento DATETIME2 NULL,
    descripcion NVARCHAR(1000) NULL,
    tasa_interes DECIMAL(5,2) NULL,
    estado NVARCHAR(20) DEFAULT 'PENDIENTE' CHECK (estado IN ('PENDIENTE', 'PAGADO', 'CANCELADO')),
    activo BIT DEFAULT 1 NOT NULL,
    fecha_creacion DATETIME2 DEFAULT GETDATE() NOT NULL,
    fecha_actualizacion DATETIME2 DEFAULT GETDATE() NOT NULL,
    CONSTRAINT FK_prestamos_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE,
    CONSTRAINT CHK_prestamos_monto CHECK (monto_pagado <= monto_total)
);
GO

-- Tabla: Pagos de Préstamos
-- Historial de pagos de préstamos
CREATE TABLE pagos_prestamos (
    id BIGINT IDENTITY(1,1) PRIMARY KEY,
    prestamo_id BIGINT NOT NULL,
    cuenta_id BIGINT NULL,
    monto_pago DECIMAL(18,2) NOT NULL,
    fecha_pago DATETIME2 DEFAULT GETDATE() NOT NULL,
    notas NVARCHAR(500) NULL,
    CONSTRAINT FK_pagos_prestamos FOREIGN KEY (prestamo_id) REFERENCES prestamos(id) ON DELETE CASCADE,
    CONSTRAINT FK_pagos_prestamos_cuenta FOREIGN KEY (cuenta_id) REFERENCES cuentas(id) ON DELETE NO ACTION
);
GO

-- =====================================================
-- ÍNDICES PARA OPTIMIZACIÓN
-- =====================================================

-- Índices para búsquedas frecuentes por usuario_id
CREATE INDEX IX_usuarios_email ON usuarios(email);
CREATE INDEX IX_cuentas_usuario ON cuentas(usuario_id);
CREATE INDEX IX_categorias_usuario ON categorias(usuario_id);
CREATE INDEX IX_transacciones_usuario ON transacciones(usuario_id);
CREATE INDEX IX_transacciones_fecha ON transacciones(fecha_transaccion);
CREATE INDEX IX_transacciones_cuenta ON transacciones(cuenta_id);
CREATE INDEX IX_presupuestos_usuario ON presupuestos(usuario_id);
CREATE INDEX IX_metas_usuario ON metas(usuario_id);
CREATE INDEX IX_prestamos_usuario ON prestamos(usuario_id);
CREATE INDEX IX_pagos_recurrentes_usuario ON pagos_recurrentes(usuario_id);
CREATE INDEX IX_tarjetas_nfc_usuario ON tarjetas_nfc(usuario_id);
CREATE INDEX IX_dispositivos_nfc_usuario ON dispositivos_nfc(usuario_id);
CREATE INDEX IX_pagos_nfc_usuario ON pagos_nfc(usuario_id);

-- =====================================================
-- DATOS INICIALES
-- =====================================================

-- Insertar tipos de transacción por defecto
INSERT INTO tipos_transaccion (nombre, descripcion) VALUES
('INGRESO', 'Dinero que ingresa'),
('GASTO', 'Dinero que sale'),
('TRANSFERENCIA', 'Movimiento entre cuentas');
GO

-- Insertar métodos de pago por defecto
INSERT INTO metodos_pago (nombre, tipo) VALUES
('Efectivo', 'EFECTIVO'),
('Tarjeta de Débito', 'TARJETA'),
('Tarjeta de Crédito', 'TARJETA'),
('Transferencia Bancaria', 'TRANSFERENCIA'),
('Cheque', 'OTRO'),
('PayPal', 'DIGITAL'),
('Apple Pay', 'DIGITAL'),
('Google Pay', 'DIGITAL');
GO

-- Insertar categorías globales por defecto
INSERT INTO categorias (usuario_id, nombre, tipo) VALUES
(NULL, 'Salario', 'INGRESO'),
(NULL, 'Bonificación', 'INGRESO'),
(NULL, 'Inversión', 'INGRESO'),
(NULL, 'Regalo', 'INGRESO'),
(NULL, 'Otro Ingreso', 'INGRESO'),
(NULL, 'Alimentación', 'GASTO'),
(NULL, 'Transporte', 'GASTO'),
(NULL, 'Entretenimiento', 'GASTO'),
(NULL, 'Salud', 'GASTO'),
(NULL, 'Servicios', 'GASTO'),
(NULL, 'Compras', 'GASTO'),
(NULL, 'Educación', 'GASTO'),
(NULL, 'Otro Gasto', 'GASTO');
GO

-- =====================================================
-- TRIGGERS PARA MANTENER CONSISTENCIA
-- =====================================================

-- Trigger para actualizar fecha_actualizacion en usuarios
CREATE TRIGGER TR_usuarios_actualizar_fecha
ON usuarios
AFTER UPDATE
AS
BEGIN
    UPDATE usuarios
    SET fecha_actualizacion = GETDATE()
    FROM inserted i
    WHERE usuarios.id = i.id;
END;
GO

-- Trigger para actualizar fecha_actualizacion en presupuestos
CREATE TRIGGER TR_presupuestos_actualizar_fecha
ON presupuestos
AFTER UPDATE
AS
BEGIN
    UPDATE presupuestos
    SET fecha_actualizacion = GETDATE()
    FROM inserted i
    WHERE presupuestos.id = i.id;
END;
GO

-- Trigger para actualizar fecha_actualizacion en metas
CREATE TRIGGER TR_metas_actualizar_fecha
ON metas
AFTER UPDATE
AS
BEGIN
    UPDATE metas
    SET fecha_actualizacion = GETDATE()
    FROM inserted i
    WHERE metas.id = i.id;
END;
GO

-- Trigger para actualizar fecha_actualizacion en prestamos
CREATE TRIGGER TR_prestamos_actualizar_fecha
ON prestamos
AFTER UPDATE
AS
BEGIN
    UPDATE prestamos
    SET fecha_actualizacion = GETDATE()
    FROM inserted i
    WHERE prestamos.id = i.id;
END;
GO

-- =====================================================
-- VISTAS ÚTILES
-- =====================================================

-- Vista para resumen de transacciones por mes
CREATE VIEW vw_resumen_transacciones_mes AS
SELECT 
    u.id AS usuario_id,
    u.nombre AS nombre_usuario,
    YEAR(t.fecha_transaccion) AS anio,
    MONTH(t.fecha_transaccion) AS mes,
    tt.nombre AS tipo_transaccion,
    SUM(CASE WHEN tt.nombre = 'INGRESO' THEN t.monto ELSE 0 END) AS total_ingresos,
    SUM(CASE WHEN tt.nombre = 'GASTO' THEN t.monto ELSE 0 END) AS total_gastos,
    SUM(CASE WHEN tt.nombre = 'INGRESO' THEN t.monto ELSE -t.monto END) AS balance
FROM usuarios u
INNER JOIN transacciones t ON u.id = t.usuario_id
INNER JOIN tipos_transaccion tt ON t.tipo_transaccion_id = tt.id
WHERE t.activa = 1
GROUP BY u.id, u.nombre, YEAR(t.fecha_transaccion), MONTH(t.fecha_transaccion), tt.nombre;
GO

-- Vista para calcular saldo actual de las cuentas
CREATE VIEW vw_saldo_cuentas AS
SELECT 
    c.id AS cuenta_id,
    c.usuario_id,
    c.nombre AS nombre_cuenta,
    c.saldo_inicial,
    ISNULL(SUM(CASE WHEN tt.nombre = 'INGRESO' THEN t.monto ELSE -t.monto END), 0) AS total_movimientos,
    c.saldo_inicial + ISNULL(SUM(CASE WHEN tt.nombre = 'INGRESO' THEN t.monto ELSE -t.monto END), 0) AS saldo_actual
FROM cuentas c
LEFT JOIN transacciones t ON c.id = t.cuenta_id AND t.activa = 1
LEFT JOIN tipos_transaccion tt ON t.tipo_transaccion_id = tt.id
WHERE c.activa = 1
GROUP BY c.id, c.usuario_id, c.nombre, c.saldo_inicial;
GO

-- Vista para progreso de metas
CREATE VIEW vw_progreso_metas AS
SELECT 
    m.id AS meta_id,
    m.usuario_id,
    m.nombre AS nombre_meta,
    m.monto_objetivo,
    m.monto_actual,
    CASE 
        WHEN m.monto_objetivo > 0 THEN (m.monto_actual / m.monto_objetivo * 100)
        ELSE 0 
    END AS porcentaje_completado
FROM metas m
WHERE m.activa = 1;
GO

-- Vista para resumen de préstamos
CREATE VIEW vw_resumen_prestamos AS
SELECT 
    p.id AS prestamo_id,
    p.usuario_id,
    p.tipo,
    p.nombre_deudor_prestador,
    p.monto_total,
    p.monto_pagado,
    p.monto_pendiente,
    p.fecha_vencimiento,
    p.estado,
    CASE 
        WHEN p.fecha_vencimiento IS NOT NULL AND p.estado = 'PENDIENTE' AND p.fecha_vencimiento < GETDATE() 
        THEN 1 
        ELSE 0 
    END AS vencido
FROM prestamos p
WHERE p.activo = 1;
GO
