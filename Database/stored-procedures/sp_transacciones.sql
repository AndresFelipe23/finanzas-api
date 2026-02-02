-- =====================================================
-- STORED PROCEDURES PARA GESTIÓN DE TRANSACCIONES
-- =====================================================

-- SP: Crear nueva transacción
CREATE OR ALTER PROCEDURE sp_transaccion_create
    @UsuarioId BIGINT,
    @CuentaId BIGINT = NULL,
    @TipoTransaccionId BIGINT,
    @CategoriaId BIGINT = NULL,
    @MetodoPagoId BIGINT = NULL,
    @Monto DECIMAL(18,2),
    @Moneda NVARCHAR(10) = 'COP',
    @Titulo NVARCHAR(150) = NULL,
    @Descripcion NVARCHAR(500) = NULL,
    @FechaTransaccion DATETIME2(7) = NULL,
    @ArchivoAdjunto NVARCHAR(500) = NULL,
    @Notas NVARCHAR(1000) = NULL,
    @Repetir BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Validar que el usuario existe
        IF NOT EXISTS (SELECT 1 FROM usuarios WHERE id = @UsuarioId AND activo = 1)
        BEGIN
            RAISERROR('Usuario no encontrado o inactivo', 16, 1);
            RETURN;
        END
        
        -- Validar que el tipo de transacción existe
        IF NOT EXISTS (SELECT 1 FROM tipos_transaccion WHERE id = @TipoTransaccionId AND activo = 1)
        BEGIN
            RAISERROR('Tipo de transacción no válido', 16, 1);
            RETURN;
        END
        
        -- Validar cuenta si se proporciona
        IF @CuentaId IS NOT NULL
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM cuentas WHERE id = @CuentaId AND usuario_id = @UsuarioId AND activa = 1)
            BEGIN
                RAISERROR('Cuenta no encontrada o no pertenece al usuario', 16, 1);
                RETURN;
            END
        END
        
        -- Validar categoría si se proporciona
        IF @CategoriaId IS NOT NULL
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM categorias WHERE id = @CategoriaId AND (usuario_id IS NULL OR usuario_id = @UsuarioId) AND activo = 1)
            BEGIN
                RAISERROR('Categoría no encontrada o no pertenece al usuario', 16, 1);
                RETURN;
            END
        END
        
        -- Validar método de pago si se proporciona
        IF @MetodoPagoId IS NOT NULL
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM metodos_pago WHERE id = @MetodoPagoId AND activo = 1)
            BEGIN
                RAISERROR('Método de pago no válido', 16, 1);
                RETURN;
            END
        END
        
        -- Si se proporciona fecha, usar la fecha del usuario pero con la hora actual del sistema
        -- Si no se proporciona, usar fecha y hora actual del sistema
        -- Convertir a zona horaria America/Bogota (UTC-5)
        DECLARE @FechaHoraLocal DATETIME2(7) = DATEADD(HOUR, -5, GETUTCDATE());

        IF @FechaTransaccion IS NULL
            SET @FechaTransaccion = @FechaHoraLocal
        ELSE
        BEGIN
            -- Combinar la fecha proporcionada con la hora actual del sistema (en hora local)
            DECLARE @HoraActual TIME = CAST(@FechaHoraLocal AS TIME);
            DECLARE @FechaSolo DATE = CAST(@FechaTransaccion AS DATE);
            -- Combinar fecha y hora: convertir DATE a DATETIME2 y agregar la hora usando DATEADD
            SET @FechaTransaccion = DATEADD(HOUR, DATEPART(HOUR, @HoraActual),
                DATEADD(MINUTE, DATEPART(MINUTE, @HoraActual),
                DATEADD(SECOND, DATEPART(SECOND, @HoraActual),
                DATEADD(MILLISECOND, DATEPART(MILLISECOND, @HoraActual),
                CAST(@FechaSolo AS DATETIME2(7))))));
        END
        
        -- Obtener ID del tipo GASTO (se usará para validación de saldo y recálculo de presupuestos)
        DECLARE @TipoGastoId BIGINT = NULL;
        SELECT @TipoGastoId = id FROM tipos_transaccion WHERE nombre = 'GASTO' AND activo = 1;
        
        -- Validar que se obtuvo el tipo GASTO
        IF @TipoGastoId IS NULL
        BEGIN
            RAISERROR('No se encontró el tipo de transacción GASTO en el sistema', 16, 1);
            RETURN;
        END
        
        -- Validar saldo suficiente si es un GASTO y tiene cuenta asociada
        IF @CuentaId IS NOT NULL
        BEGIN
            -- Si es un gasto, verificar que el saldo sea suficiente
            IF @TipoTransaccionId = @TipoGastoId
            BEGIN
                DECLARE @SaldoActual DECIMAL(18,2);
                EXEC sp_cuenta_get_saldo @CuentaId = @CuentaId, @UsuarioId = @UsuarioId, @Saldo = @SaldoActual OUTPUT;
                
                IF @SaldoActual < @Monto
                BEGIN
                    DECLARE @MensajeError NVARCHAR(500) = FORMATMESSAGE(
                        'Saldo insuficiente. Saldo disponible: %s %s, Monto requerido: %s %s',
                        FORMAT(@SaldoActual, 'N2'),
                        @Moneda,
                        FORMAT(@Monto, 'N2'),
                        @Moneda
                    );
                    RAISERROR(@MensajeError, 16, 1);
                    RETURN;
                END
            END
        END
        
        -- Insertar la transacción
        INSERT INTO transacciones (
            usuario_id,
            cuenta_id,
            tipo_transaccion_id,
            categoria_id,
            metodo_pago_id,
            monto,
            moneda,
            titulo,
            descripcion,
            fecha_transaccion,
            archivo_adjunto,
            notas,
            repetir,
            activa,
            fecha_creacion
        )
        VALUES (
            @UsuarioId,
            @CuentaId,
            @TipoTransaccionId,
            @CategoriaId,
            @MetodoPagoId,
            @Monto,
            @Moneda,
            @Titulo,
            @Descripcion,
            @FechaTransaccion,
            @ArchivoAdjunto,
            @Notas,
            @Repetir,
            1,
            CAST(@FechaHoraLocal AS DATETIME2(0))
        )
        
        -- Recalcular presupuestos afectados si es un GASTO
        -- Comentado temporalmente para evitar errores - se puede activar después
        -- IF @TipoTransaccionId = @TipoGastoId AND @TipoGastoId IS NOT NULL
        -- BEGIN
        --     -- Recalcular presupuestos afectados (implementación futura)
        -- END
        
        -- Retornar la transacción creada
        DECLARE @NewTransaccionId BIGINT = SCOPE_IDENTITY();
        
        IF @NewTransaccionId IS NULL
        BEGIN
            RAISERROR('Error al crear la transacción: no se obtuvo el ID', 16, 1);
            RETURN;
        END
        
        SELECT 
            t.id,
            t.usuario_id,
            t.cuenta_id,
            t.tipo_transaccion_id,
            tt.nombre AS tipo_nombre,
            t.categoria_id,
            c.nombre AS categoria_nombre,
            c.color AS categoria_color,
            c.icono AS categoria_icono,
            t.metodo_pago_id,
            mp.nombre AS metodo_pago_nombre,
            t.monto,
            ISNULL(t.moneda, 'COP') AS moneda,
            t.titulo,
            t.descripcion,
            t.fecha_transaccion,
            t.archivo_adjunto,
            t.notas,
            t.repetir,
            t.activa,
            t.fecha_creacion
        FROM transacciones t
        LEFT JOIN tipos_transaccion tt ON t.tipo_transaccion_id = tt.id
        LEFT JOIN categorias c ON t.categoria_id = c.id
        LEFT JOIN metodos_pago mp ON t.metodo_pago_id = mp.id
        WHERE t.id = @NewTransaccionId
        
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

-- SP: Actualizar transacción
CREATE OR ALTER PROCEDURE sp_transaccion_update
    @Id BIGINT,
    @UsuarioId BIGINT,
    @CuentaId BIGINT = NULL,
    @TipoTransaccionId BIGINT = NULL,
    @CategoriaId BIGINT = NULL,
    @MetodoPagoId BIGINT = NULL,
    @Monto DECIMAL(18,2) = NULL,
    @Moneda NVARCHAR(10) = NULL,
    @Titulo NVARCHAR(150) = NULL,
    @Descripcion NVARCHAR(500) = NULL,
    @FechaTransaccion DATETIME2(0) = NULL,
    @ArchivoAdjunto NVARCHAR(500) = NULL,
    @Notas NVARCHAR(1000) = NULL,
    @Repetir BIT = NULL,
    @Activa BIT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Validar que la transacción existe y pertenece al usuario
        -- Removido el filtro AND activa = 1 para permitir restaurar transacciones eliminadas
        IF NOT EXISTS (SELECT 1 FROM transacciones WHERE id = @Id AND usuario_id = @UsuarioId)
        BEGIN
            RAISERROR('Transacción no encontrada o no pertenece al usuario', 16, 1);
            RETURN;
        END
        
        -- Validar tipo de transacción si se proporciona
        IF @TipoTransaccionId IS NOT NULL
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM tipos_transaccion WHERE id = @TipoTransaccionId AND activo = 1)
            BEGIN
                RAISERROR('Tipo de transacción no válido', 16, 1);
                RETURN;
            END
        END
        
        -- Validar cuenta si se proporciona
        IF @CuentaId IS NOT NULL
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM cuentas WHERE id = @CuentaId AND usuario_id = @UsuarioId AND activa = 1)
            BEGIN
                RAISERROR('Cuenta no encontrada o no pertenece al usuario', 16, 1);
                RETURN;
            END
        END
        
        -- Validar categoría si se proporciona
        IF @CategoriaId IS NOT NULL
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM categorias WHERE id = @CategoriaId AND (usuario_id IS NULL OR usuario_id = @UsuarioId) AND activo = 1)
            BEGIN
                RAISERROR('Categoría no encontrada o no pertenece al usuario', 16, 1);
                RETURN;
            END
        END
        
        -- Obtener valores antiguos para recalcular presupuestos afectados
        DECLARE @FechaTransaccionAnterior DATETIME2(7);
        DECLARE @CategoriaIdAnterior BIGINT;
        DECLARE @CuentaIdAnterior BIGINT;
        DECLARE @TipoTransaccionIdAnterior BIGINT;
        
        SELECT 
            @FechaTransaccionAnterior = fecha_transaccion,
            @CategoriaIdAnterior = categoria_id,
            @CuentaIdAnterior = cuenta_id,
            @TipoTransaccionIdAnterior = tipo_transaccion_id
        FROM transacciones
        WHERE id = @Id;
        
        -- Actualizar solo los campos proporcionados
        UPDATE transacciones
        SET
            cuenta_id = ISNULL(@CuentaId, cuenta_id),
            tipo_transaccion_id = ISNULL(@TipoTransaccionId, tipo_transaccion_id),
            categoria_id = ISNULL(@CategoriaId, categoria_id),
            metodo_pago_id = ISNULL(@MetodoPagoId, metodo_pago_id),
            monto = ISNULL(@Monto, monto),
            moneda = ISNULL(@Moneda, moneda),
            titulo = ISNULL(@Titulo, titulo),
            descripcion = ISNULL(@Descripcion, descripcion),
            fecha_transaccion = ISNULL(CAST(@FechaTransaccion AS DATETIME2(0)), fecha_transaccion),
            archivo_adjunto = ISNULL(@ArchivoAdjunto, archivo_adjunto),
            notas = ISNULL(@Notas, notas),
            repetir = ISNULL(@Repetir, repetir),
            activa = ISNULL(@Activa, activa)
        WHERE id = @Id
        
        -- Obtener valores nuevos
        DECLARE @FechaTransaccionNueva DATETIME2(7);
        DECLARE @CategoriaIdNueva BIGINT;
        DECLARE @CuentaIdNueva BIGINT;
        DECLARE @TipoTransaccionIdNuevo BIGINT;
        
        SELECT 
            @FechaTransaccionNueva = fecha_transaccion,
            @CategoriaIdNueva = categoria_id,
            @CuentaIdNueva = cuenta_id,
            @TipoTransaccionIdNuevo = tipo_transaccion_id
        FROM transacciones
        WHERE id = @Id;
        
        -- Recalcular presupuestos afectados si es un GASTO o si cambió a GASTO
        DECLARE @TipoGastoId BIGINT;
        SELECT @TipoGastoId = id FROM tipos_transaccion WHERE nombre = 'GASTO' AND activo = 1;
        
        IF @TipoTransaccionIdNuevo = @TipoGastoId OR @TipoTransaccionIdAnterior = @TipoGastoId
        BEGIN
            -- Buscar presupuestos afectados (tanto por valores antiguos como nuevos)
            DECLARE @PresupuestoId BIGINT;
            DECLARE presupuestos_cursor CURSOR FOR
                SELECT DISTINCT id
                FROM presupuestos
                WHERE usuario_id = @UsuarioId
                  AND activo = 1
                  AND (
                      -- Presupuestos afectados por valores antiguos
                      (@FechaTransaccionAnterior >= fecha_inicio AND @FechaTransaccionAnterior <= DATEADD(SECOND, 86399, fecha_fin)
                       AND (categoria_id IS NULL OR categoria_id = @CategoriaIdAnterior)
                       AND (cuenta_id IS NULL OR cuenta_id = @CuentaIdAnterior))
                      OR
                      -- Presupuestos afectados por valores nuevos
                      (@FechaTransaccionNueva >= fecha_inicio AND @FechaTransaccionNueva <= DATEADD(SECOND, 86399, fecha_fin)
                       AND (categoria_id IS NULL OR categoria_id = @CategoriaIdNueva)
                       AND (cuenta_id IS NULL OR cuenta_id = @CuentaIdNueva))
                  );
            
            OPEN presupuestos_cursor;
            FETCH NEXT FROM presupuestos_cursor INTO @PresupuestoId;
            
            WHILE @@FETCH_STATUS = 0
            BEGIN
                BEGIN TRY
                    EXEC sp_presupuesto_recalc_gasto @Id = @PresupuestoId, @UsuarioId = @UsuarioId;
                END TRY
                BEGIN CATCH
                    -- Continuar con el siguiente presupuesto si hay error
                END CATCH
                
                FETCH NEXT FROM presupuestos_cursor INTO @PresupuestoId;
            END
            
            CLOSE presupuestos_cursor;
            DEALLOCATE presupuestos_cursor;
        END
        
        -- Retornar la transacción actualizada
        SELECT 
            t.id,
            t.usuario_id,
            t.cuenta_id,
            t.tipo_transaccion_id,
            tt.nombre AS tipo_nombre,
            t.categoria_id,
            c.nombre AS categoria_nombre,
            c.color AS categoria_color,
            c.icono AS categoria_icono,
            t.metodo_pago_id,
            mp.nombre AS metodo_pago_nombre,
            t.monto,
            t.moneda,
            t.titulo,
            t.descripcion,
            t.fecha_transaccion,
            t.archivo_adjunto,
            t.notas,
            t.repetir,
            t.activa,
            t.fecha_creacion
        FROM transacciones t
        LEFT JOIN tipos_transaccion tt ON t.tipo_transaccion_id = tt.id
        LEFT JOIN categorias c ON t.categoria_id = c.id
        LEFT JOIN metodos_pago mp ON t.metodo_pago_id = mp.id
        WHERE t.id = @Id
        
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

-- SP: Eliminar transacción (soft delete)
CREATE OR ALTER PROCEDURE sp_transaccion_delete
    @Id BIGINT,
    @UsuarioId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Validar que la transacción existe y pertenece al usuario
        IF NOT EXISTS (SELECT 1 FROM transacciones WHERE id = @Id AND usuario_id = @UsuarioId)
        BEGIN
            RAISERROR('Transacción no encontrada o no pertenece al usuario', 16, 1);
            RETURN;
        END
        
        -- Obtener información de la transacción antes de eliminarla para recalcular presupuestos
        DECLARE @FechaTransaccion DATETIME2(7);
        DECLARE @CategoriaId BIGINT;
        DECLARE @CuentaId BIGINT;
        DECLARE @TipoTransaccionId BIGINT;
        
        SELECT 
            @FechaTransaccion = fecha_transaccion,
            @CategoriaId = categoria_id,
            @CuentaId = cuenta_id,
            @TipoTransaccionId = tipo_transaccion_id
        FROM transacciones
        WHERE id = @Id;
        
        -- Soft delete
        UPDATE transacciones
        SET activa = 0
        WHERE id = @Id
        
        -- Recalcular presupuestos afectados si era un GASTO
        DECLARE @TipoGastoId BIGINT;
        SELECT @TipoGastoId = id FROM tipos_transaccion WHERE nombre = 'GASTO' AND activo = 1;
        
        IF @TipoTransaccionId = @TipoGastoId
        BEGIN
            -- Buscar presupuestos que podrían verse afectados por esta transacción
            DECLARE @PresupuestoId BIGINT;
            DECLARE presupuestos_cursor CURSOR FOR
                SELECT id
                FROM presupuestos
                WHERE usuario_id = @UsuarioId
                  AND activo = 1
                  AND @FechaTransaccion >= fecha_inicio
                  AND @FechaTransaccion <= DATEADD(SECOND, 86399, fecha_fin)
                  AND (categoria_id IS NULL OR categoria_id = @CategoriaId)
                  AND (cuenta_id IS NULL OR cuenta_id = @CuentaId);
            
            OPEN presupuestos_cursor;
            FETCH NEXT FROM presupuestos_cursor INTO @PresupuestoId;
            
            WHILE @@FETCH_STATUS = 0
            BEGIN
                BEGIN TRY
                    EXEC sp_presupuesto_recalc_gasto @Id = @PresupuestoId, @UsuarioId = @UsuarioId;
                END TRY
                BEGIN CATCH
                    -- Continuar con el siguiente presupuesto si hay error
                END CATCH
                
                FETCH NEXT FROM presupuestos_cursor INTO @PresupuestoId;
            END
            
            CLOSE presupuestos_cursor;
            DEALLOCATE presupuestos_cursor;
        END
        
        SELECT 1 AS success
        
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

-- SP: Eliminar transacción permanentemente (hard delete)
CREATE OR ALTER PROCEDURE sp_transaccion_delete_permanently
    @Id BIGINT,
    @UsuarioId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Validar que la transacción existe y pertenece al usuario
        IF NOT EXISTS (SELECT 1 FROM transacciones WHERE id = @Id AND usuario_id = @UsuarioId)
        BEGIN
            RAISERROR('Transacción no encontrada o no pertenece al usuario', 16, 1);
            RETURN;
        END
        
        -- Obtener información de la transacción antes de eliminarla para recalcular presupuestos
        DECLARE @FechaTransaccion DATETIME2(7);
        DECLARE @CategoriaId BIGINT;
        DECLARE @CuentaId BIGINT;
        DECLARE @TipoTransaccionId BIGINT;
        
        SELECT 
            @FechaTransaccion = fecha_transaccion,
            @CategoriaId = categoria_id,
            @CuentaId = cuenta_id,
            @TipoTransaccionId = tipo_transaccion_id
        FROM transacciones
        WHERE id = @Id;
        
        -- Eliminar permanentemente de la base de datos
        DELETE FROM transacciones
        WHERE id = @Id
        
        -- Recalcular presupuestos afectados si era un GASTO
        DECLARE @TipoGastoId BIGINT;
        SELECT @TipoGastoId = id FROM tipos_transaccion WHERE nombre = 'GASTO' AND activo = 1;
        
        IF @TipoTransaccionId = @TipoGastoId
        BEGIN
            -- Buscar presupuestos que podrían verse afectados por esta transacción
            DECLARE @PresupuestoId BIGINT;
            DECLARE presupuestos_cursor CURSOR FOR
                SELECT id
                FROM presupuestos
                WHERE usuario_id = @UsuarioId
                  AND activo = 1
                  AND @FechaTransaccion >= fecha_inicio
                  AND @FechaTransaccion <= DATEADD(SECOND, 86399, fecha_fin)
                  AND (categoria_id IS NULL OR categoria_id = @CategoriaId)
                  AND (cuenta_id IS NULL OR cuenta_id = @CuentaId);
            
            OPEN presupuestos_cursor;
            FETCH NEXT FROM presupuestos_cursor INTO @PresupuestoId;
            
            WHILE @@FETCH_STATUS = 0
            BEGIN
                BEGIN TRY
                    EXEC sp_presupuesto_recalc_gasto @Id = @PresupuestoId, @UsuarioId = @UsuarioId;
                END TRY
                BEGIN CATCH
                    -- Continuar con el siguiente presupuesto si hay error
                END CATCH
                
                FETCH NEXT FROM presupuestos_cursor INTO @PresupuestoId;
            END
            
            CLOSE presupuestos_cursor;
            DEALLOCATE presupuestos_cursor;
        END
        
        SELECT 1 AS success
        
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

-- SP: Crear transferencia entre cuentas
CREATE OR ALTER PROCEDURE sp_transaccion_create_transfer
    @UsuarioId BIGINT,
    @CuentaOrigenId BIGINT,
    @CuentaDestinoId BIGINT,
    @Monto DECIMAL(18,2),
    @Moneda NVARCHAR(10) = 'COP',
    @Titulo NVARCHAR(150) = NULL,
    @Descripcion NVARCHAR(500) = NULL,
    @FechaTransaccion DATETIME2(7) = NULL,
    @Notas NVARCHAR(1000) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Validar que el usuario existe
        IF NOT EXISTS (SELECT 1 FROM usuarios WHERE id = @UsuarioId AND activo = 1)
        BEGIN
            RAISERROR('Usuario no encontrado o inactivo', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END
        
        -- Validar que las cuentas existen y pertenecen al usuario
        IF NOT EXISTS (SELECT 1 FROM cuentas WHERE id = @CuentaOrigenId AND usuario_id = @UsuarioId AND activa = 1)
        BEGIN
            RAISERROR('Cuenta de origen no encontrada o inactiva', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END
        
        IF NOT EXISTS (SELECT 1 FROM cuentas WHERE id = @CuentaDestinoId AND usuario_id = @UsuarioId AND activa = 1)
        BEGIN
            RAISERROR('Cuenta de destino no encontrada o inactiva', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END
        
        -- Validar que no sean la misma cuenta
        IF @CuentaOrigenId = @CuentaDestinoId
        BEGIN
            RAISERROR('La cuenta de origen y destino no pueden ser la misma', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END
        
        -- Validar monto
        IF @Monto <= 0
        BEGIN
            RAISERROR('El monto debe ser mayor a cero', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END
        
        -- Obtener ID del tipo TRANSFERENCIA
        DECLARE @TipoTransferenciaId BIGINT;
        SELECT @TipoTransferenciaId = id FROM tipos_transaccion WHERE nombre = 'TRANSFERENCIA' AND activo = 1;
        
        IF @TipoTransferenciaId IS NULL
        BEGIN
            RAISERROR('Tipo de transacción TRANSFERENCIA no encontrado', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END
        
        -- Si se proporciona fecha, usar la fecha del usuario pero con la hora actual del sistema
        -- Si no se proporciona, usar fecha y hora actual del sistema
        -- Convertir a zona horaria America/Bogota (UTC-5)
        DECLARE @FechaHoraLocal2 DATETIME2(7) = DATEADD(HOUR, -5, GETUTCDATE());

        IF @FechaTransaccion IS NULL
            SET @FechaTransaccion = @FechaHoraLocal2
        ELSE
        BEGIN
            -- Combinar la fecha proporcionada con la hora actual del sistema (en hora local)
            DECLARE @HoraActual2 TIME = CAST(@FechaHoraLocal2 AS TIME);
            DECLARE @FechaSolo2 DATE = CAST(@FechaTransaccion AS DATE);
            -- Combinar fecha y hora: convertir DATE a DATETIME2 y agregar la hora usando DATEADD
            SET @FechaTransaccion = DATEADD(HOUR, DATEPART(HOUR, @HoraActual2),
                DATEADD(MINUTE, DATEPART(MINUTE, @HoraActual2),
                DATEADD(SECOND, DATEPART(SECOND, @HoraActual2),
                DATEADD(MILLISECOND, DATEPART(MILLISECOND, @HoraActual2),
                CAST(@FechaSolo2 AS DATETIME2(7))))));
        END
        
        -- Crear título por defecto si no se proporciona
        IF @Titulo IS NULL
        BEGIN
            DECLARE @NombreOrigen NVARCHAR(100);
            DECLARE @NombreDestino NVARCHAR(100);
            SELECT @NombreOrigen = nombre FROM cuentas WHERE id = @CuentaOrigenId;
            SELECT @NombreDestino = nombre FROM cuentas WHERE id = @CuentaDestinoId;
            SET @Titulo = 'Transferencia de ' + @NombreOrigen + ' a ' + @NombreDestino;
        END
        
        -- Crear la transacción de salida (GASTO en cuenta origen)
        DECLARE @TipoGastoId BIGINT;
        SELECT @TipoGastoId = id FROM tipos_transaccion WHERE nombre = 'GASTO' AND activo = 1;
        
        INSERT INTO transacciones (
            usuario_id, cuenta_id, tipo_transaccion_id, categoria_id, metodo_pago_id,
            monto, moneda, titulo, descripcion, fecha_transaccion, archivo_adjunto, notas, repetir, activa, fecha_creacion
        )
        VALUES (
            @UsuarioId, @CuentaOrigenId, @TipoGastoId, NULL, NULL,
            @Monto, @Moneda, @Titulo, @Descripcion, @FechaTransaccion, NULL, @Notas, 0, 1, @FechaHoraLocal2
        )

        DECLARE @TransaccionOrigenId BIGINT = SCOPE_IDENTITY();

        -- Crear la transacción de entrada (INGRESO en cuenta destino)
        DECLARE @TipoIngresoId BIGINT;
        SELECT @TipoIngresoId = id FROM tipos_transaccion WHERE nombre = 'INGRESO' AND activo = 1;

        INSERT INTO transacciones (
            usuario_id, cuenta_id, tipo_transaccion_id, categoria_id, metodo_pago_id,
            monto, moneda, titulo, descripcion, fecha_transaccion, archivo_adjunto, notas, repetir, activa, fecha_creacion
        )
        VALUES (
            @UsuarioId, @CuentaDestinoId, @TipoIngresoId, NULL, NULL,
            @Monto, @Moneda, @Titulo, @Descripcion, @FechaTransaccion, NULL, @Notas, 0, 1, @FechaHoraLocal2
        )
        
        DECLARE @TransaccionDestinoId BIGINT = SCOPE_IDENTITY();
        
        -- Recalcular presupuestos afectados por la transacción de GASTO (cuenta origen)
        -- La transacción de INGRESO no afecta presupuestos
        DECLARE @PresupuestoId BIGINT;
        DECLARE presupuestos_cursor CURSOR FOR
            SELECT id
            FROM presupuestos
            WHERE usuario_id = @UsuarioId
              AND activo = 1
              AND @FechaTransaccion >= fecha_inicio
              AND @FechaTransaccion <= DATEADD(SECOND, 86399, fecha_fin)
              AND (categoria_id IS NULL)  -- Transferencias no tienen categoría
              AND (cuenta_id IS NULL OR cuenta_id = @CuentaOrigenId);
        
        OPEN presupuestos_cursor;
        FETCH NEXT FROM presupuestos_cursor INTO @PresupuestoId;
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            BEGIN TRY
                EXEC sp_presupuesto_recalc_gasto @Id = @PresupuestoId, @UsuarioId = @UsuarioId;
            END TRY
            BEGIN CATCH
                -- Continuar con el siguiente presupuesto si hay error
            END CATCH
            
            FETCH NEXT FROM presupuestos_cursor INTO @PresupuestoId;
        END
        
        CLOSE presupuestos_cursor;
        DEALLOCATE presupuestos_cursor;
        
        -- Retornar ambas transacciones
        SELECT 
            t.id,
            t.usuario_id,
            t.cuenta_id,
            ct.nombre AS cuenta_nombre,
            t.tipo_transaccion_id,
            tt.nombre AS tipo_nombre,
            t.categoria_id,
            c.nombre AS categoria_nombre,
            c.color AS categoria_color,
            c.icono AS categoria_icono,
            t.metodo_pago_id,
            mp.nombre AS metodo_pago_nombre,
            t.monto,
            t.moneda,
            t.titulo,
            t.descripcion,
            t.fecha_transaccion,
            t.archivo_adjunto,
            t.notas,
            t.repetir,
            t.activa,
            t.fecha_creacion
        FROM transacciones t
        LEFT JOIN tipos_transaccion tt ON t.tipo_transaccion_id = tt.id
        LEFT JOIN categorias c ON t.categoria_id = c.id
        LEFT JOIN metodos_pago mp ON t.metodo_pago_id = mp.id
        LEFT JOIN cuentas ct ON t.cuenta_id = ct.id
        WHERE t.id IN (@TransaccionOrigenId, @TransaccionDestinoId)
        ORDER BY t.cuenta_id, t.tipo_transaccion_id;
        
        COMMIT TRANSACTION;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- SP: Obtener transacción por ID
CREATE OR ALTER PROCEDURE sp_transaccion_get_by_id
    @Id BIGINT,
    @UsuarioId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        t.id,
        t.usuario_id,
        t.cuenta_id,
        t.tipo_transaccion_id,
        tt.nombre AS tipo_nombre,
        t.categoria_id,
        c.nombre AS categoria_nombre,
        c.color AS categoria_color,
        c.icono AS categoria_icono,
        t.metodo_pago_id,
        mp.nombre AS metodo_pago_nombre,
        t.monto,
        t.moneda,
        t.titulo,
        t.descripcion,
        t.fecha_transaccion,
        t.archivo_adjunto,
        t.notas,
        t.repetir,
        t.activa,
        t.fecha_creacion
    FROM transacciones t
    LEFT JOIN tipos_transaccion tt ON t.tipo_transaccion_id = tt.id
    LEFT JOIN categorias c ON t.categoria_id = c.id
    LEFT JOIN metodos_pago mp ON t.metodo_pago_id = mp.id
    WHERE t.id = @Id AND t.usuario_id = @UsuarioId
    -- Removido el filtro AND t.activa = 1 para permitir obtener transacciones eliminadas
END;
GO

-- SP: Obtener todas las transacciones del usuario
CREATE OR ALTER PROCEDURE sp_transaccion_get_by_user
    @UsuarioId BIGINT,
    @FechaInicio DATE = NULL,
    @FechaFin DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        t.id,
        t.usuario_id,
        t.cuenta_id,
        ct.nombre AS cuenta_nombre,
        t.tipo_transaccion_id,
        tt.nombre AS tipo_nombre,
        t.categoria_id,
        c.nombre AS categoria_nombre,
        c.color AS categoria_color,
        c.icono AS categoria_icono,
        t.metodo_pago_id,
        mp.nombre AS metodo_pago_nombre,
        t.monto,
        t.moneda,
        t.titulo,
        t.descripcion,
        t.fecha_transaccion,
        t.archivo_adjunto,
        t.notas,
        t.repetir,
        t.activa,
        t.fecha_creacion
    FROM transacciones t
    LEFT JOIN tipos_transaccion tt ON t.tipo_transaccion_id = tt.id
    LEFT JOIN categorias c ON t.categoria_id = c.id
    LEFT JOIN metodos_pago mp ON t.metodo_pago_id = mp.id
    LEFT JOIN cuentas ct ON t.cuenta_id = ct.id
    WHERE t.usuario_id = @UsuarioId 
        -- Removido el filtro AND t.activa = 1 para permitir obtener todas las transacciones
        -- El frontend filtrará según necesite (activas o eliminadas)
        AND (@FechaInicio IS NULL OR t.fecha_transaccion >= @FechaInicio)
        AND (@FechaFin IS NULL OR t.fecha_transaccion <= @FechaFin)
    ORDER BY t.fecha_transaccion DESC
END;
GO

-- SP: Obtener transacciones por cuenta
CREATE OR ALTER PROCEDURE sp_transaccion_get_by_account
    @UsuarioId BIGINT,
    @CuentaId BIGINT,
    @FechaInicio DATE = NULL,
    @FechaFin DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        t.id,
        t.usuario_id,
        t.cuenta_id,
        ct.nombre AS cuenta_nombre,
        t.tipo_transaccion_id,
        tt.nombre AS tipo_nombre,
        t.categoria_id,
        c.nombre AS categoria_nombre,
        c.color AS categoria_color,
        c.icono AS categoria_icono,
        t.metodo_pago_id,
        mp.nombre AS metodo_pago_nombre,
        t.monto,
        t.moneda,
        t.titulo,
        t.descripcion,
        t.fecha_transaccion,
        t.archivo_adjunto,
        t.notas,
        t.repetir,
        t.activa,
        t.fecha_creacion
    FROM transacciones t
    LEFT JOIN tipos_transaccion tt ON t.tipo_transaccion_id = tt.id
    LEFT JOIN categorias c ON t.categoria_id = c.id
    LEFT JOIN metodos_pago mp ON t.metodo_pago_id = mp.id
    LEFT JOIN cuentas ct ON t.cuenta_id = ct.id
    WHERE t.usuario_id = @UsuarioId 
        AND t.cuenta_id = @CuentaId
        AND t.activa = 1
        AND (@FechaInicio IS NULL OR t.fecha_transaccion >= @FechaInicio)
        AND (@FechaFin IS NULL OR t.fecha_transaccion <= @FechaFin)
    ORDER BY t.fecha_transaccion DESC
END;
GO

-- SP: Obtener transacciones por categoría
CREATE OR ALTER PROCEDURE sp_transaccion_get_by_category
    @UsuarioId BIGINT,
    @CategoriaId BIGINT,
    @FechaInicio DATE = NULL,
    @FechaFin DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        t.id,
        t.usuario_id,
        t.cuenta_id,
        ct.nombre AS cuenta_nombre,
        t.tipo_transaccion_id,
        tt.nombre AS tipo_nombre,
        t.categoria_id,
        c.nombre AS categoria_nombre,
        c.color AS categoria_color,
        c.icono AS categoria_icono,
        t.metodo_pago_id,
        mp.nombre AS metodo_pago_nombre,
        t.monto,
        t.moneda,
        t.titulo,
        t.descripcion,
        t.fecha_transaccion,
        t.archivo_adjunto,
        t.notas,
        t.repetir,
        t.activa,
        t.fecha_creacion
    FROM transacciones t
    LEFT JOIN tipos_transaccion tt ON t.tipo_transaccion_id = tt.id
    LEFT JOIN categorias c ON t.categoria_id = c.id
    LEFT JOIN metodos_pago mp ON t.metodo_pago_id = mp.id
    LEFT JOIN cuentas ct ON t.cuenta_id = ct.id
    WHERE t.usuario_id = @UsuarioId 
        AND t.categoria_id = @CategoriaId
        AND t.activa = 1
        AND (@FechaInicio IS NULL OR t.fecha_transaccion >= @FechaInicio)
        AND (@FechaFin IS NULL OR t.fecha_transaccion <= @FechaFin)
    ORDER BY t.fecha_transaccion DESC
END;
GO

-- SP: Obtener transacciones por tipo (INGRESO/GASTO)
CREATE OR ALTER PROCEDURE sp_transaccion_get_by_type
    @UsuarioId BIGINT,
    @TipoTransaccionId BIGINT,
    @FechaInicio DATE = NULL,
    @FechaFin DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        t.id,
        t.usuario_id,
        t.cuenta_id,
        ct.nombre AS cuenta_nombre,
        t.tipo_transaccion_id,
        tt.nombre AS tipo_nombre,
        t.categoria_id,
        c.nombre AS categoria_nombre,
        c.color AS categoria_color,
        c.icono AS categoria_icono,
        t.metodo_pago_id,
        mp.nombre AS metodo_pago_nombre,
        t.monto,
        t.moneda,
        t.titulo,
        t.descripcion,
        t.fecha_transaccion,
        t.archivo_adjunto,
        t.notas,
        t.repetir,
        t.activa,
        t.fecha_creacion
    FROM transacciones t
    LEFT JOIN tipos_transaccion tt ON t.tipo_transaccion_id = tt.id
    LEFT JOIN categorias c ON t.categoria_id = c.id
    LEFT JOIN metodos_pago mp ON t.metodo_pago_id = mp.id
    LEFT JOIN cuentas ct ON t.cuenta_id = ct.id
    WHERE t.usuario_id = @UsuarioId 
        AND t.tipo_transaccion_id = @TipoTransaccionId
        AND t.activa = 1
        AND (@FechaInicio IS NULL OR t.fecha_transaccion >= @FechaInicio)
        AND (@FechaFin IS NULL OR t.fecha_transaccion <= @FechaFin)
    ORDER BY t.fecha_transaccion DESC
END;
GO

-- SP: Resumen de transacciones del usuario
CREATE OR ALTER PROCEDURE sp_transaccion_get_summary
    @UsuarioId BIGINT,
    @FechaInicio DATE = NULL,
    @FechaFin DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Declarar variables para los tipos
    DECLARE @TipoIngresoId BIGINT;
    DECLARE @TipoGastoId BIGINT;
    
    -- Obtener IDs de tipos
    SELECT @TipoIngresoId = id FROM tipos_transaccion WHERE nombre = 'INGRESO' AND activo = 1;
    SELECT @TipoGastoId = id FROM tipos_transaccion WHERE nombre = 'GASTO' AND activo = 1;
    
    SELECT 
        -- Resumen general
        COUNT(*) AS total_transacciones,
        SUM(CASE WHEN t.tipo_transaccion_id = @TipoIngresoId THEN t.monto ELSE 0 END) AS total_ingresos,
        SUM(CASE WHEN t.tipo_transaccion_id = @TipoGastoId THEN t.monto ELSE 0 END) AS total_gastos,
        SUM(CASE WHEN t.tipo_transaccion_id = @TipoIngresoId THEN t.monto ELSE 0 END) - 
        SUM(CASE WHEN t.tipo_transaccion_id = @TipoGastoId THEN t.monto ELSE 0 END) AS balance,
        -- Por categoría
        t.categoria_id,
        c.nombre AS categoria_nombre,
        c.color AS categoria_color,
        c.icono AS categoria_icono,
        COUNT(CASE WHEN t.categoria_id IS NOT NULL THEN 1 END) AS transacciones_categoria,
        SUM(CASE WHEN t.tipo_transaccion_id = @TipoIngresoId AND t.categoria_id IS NOT NULL THEN t.monto ELSE 0 END) AS ingresos_categoria,
        SUM(CASE WHEN t.tipo_transaccion_id = @TipoGastoId AND t.categoria_id IS NOT NULL THEN t.monto ELSE 0 END) AS gastos_categoria
    FROM transacciones t
    LEFT JOIN categorias c ON t.categoria_id = c.id
    WHERE t.usuario_id = @UsuarioId 
        AND t.activa = 1
        AND (@FechaInicio IS NULL OR t.fecha_transaccion >= @FechaInicio)
        AND (@FechaFin IS NULL OR t.fecha_transaccion <= @FechaFin)
    GROUP BY t.categoria_id, c.nombre, c.color, c.icono
    ORDER BY transacciones_categoria DESC
END;
GO

PRINT 'Procedimientos almacenados de transacciones creados exitosamente'
GO

