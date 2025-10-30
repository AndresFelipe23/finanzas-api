import { Entity, Column, PrimaryGeneratedColumn, CreateDateColumn } from 'typeorm';

@Entity('transacciones')
export class Transaccion {
  @PrimaryGeneratedColumn({ type: 'bigint' })
  id: number;

  @Column({ type: 'bigint', name: 'usuario_id' })
  usuarioId: number;

  @Column({ type: 'bigint', name: 'cuenta_id', nullable: true })
  cuentaId: number | null;

  @Column({ type: 'bigint', name: 'tipo_transaccion_id' })
  tipoTransaccionId: number;

  @Column({ type: 'bigint', name: 'categoria_id', nullable: true })
  categoriaId: number | null;

  @Column({ type: 'bigint', name: 'metodo_pago_id', nullable: true })
  metodoPagoId: number | null;

  @Column({ type: 'decimal', precision: 18, scale: 2 })
  monto: number;

  @Column({ type: 'nvarchar', length: 10, default: 'COP' })
  moneda: string;

  @Column({ type: 'nvarchar', length: 150, nullable: true })
  titulo: string | null;

  @Column({ type: 'nvarchar', length: 500, nullable: true })
  descripcion: string;

  @Column({ type: 'datetime2', name: 'fecha_transaccion' })
  fechaTransaccion: Date;

  @Column({ type: 'nvarchar', length: 500, name: 'archivo_adjunto', nullable: true })
  archivoAdjunto: string | null;

  @Column({ type: 'nvarchar', length: 1000, nullable: true })
  notas: string | null;

  @Column({ type: 'bit', default: false })
  repetir: boolean;

  @Column({ type: 'bit', default: true })
  activa: boolean;

  @CreateDateColumn({ type: 'datetime2', name: 'fecha_creacion' })
  fechaCreacion: Date;
}

