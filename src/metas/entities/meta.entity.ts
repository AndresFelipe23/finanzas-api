import { Entity, Column, PrimaryGeneratedColumn, CreateDateColumn, UpdateDateColumn } from 'typeorm';

@Entity('metas')
export class Meta {
  @PrimaryGeneratedColumn({ type: 'bigint' })
  id: number;

  @Column({ type: 'bigint', name: 'usuario_id' })
  usuarioId: number;

  @Column({ type: 'nvarchar', length: 200 })
  nombre: string;

  @Column({ type: 'nvarchar', length: 1000, nullable: true })
  descripcion: string | null;

  @Column({ type: 'decimal', precision: 18, scale: 2, name: 'monto_objetivo' })
  montoObjetivo: number;

  @Column({ type: 'decimal', precision: 18, scale: 2, default: 0, name: 'monto_actual' })
  montoActual: number;

  @Column({ type: 'datetime2', name: 'fecha_objetivo' })
  fechaObjetivo: Date;

  @Column({ type: 'nvarchar', length: 50, nullable: true })
  icono: string | null;

  @Column({ type: 'nvarchar', length: 7, nullable: true })
  color: string | null;

  @Column({ type: 'bit', default: true })
  activa: boolean;

  @CreateDateColumn({ type: 'datetime2', name: 'fecha_creacion' })
  fechaCreacion: Date;

  @UpdateDateColumn({ type: 'datetime2', name: 'fecha_actualizacion' })
  fechaActualizacion: Date;
}

@Entity('aportes_metas')
export class AporteMeta {
  @PrimaryGeneratedColumn({ type: 'bigint' })
  id: number;

  @Column({ type: 'bigint', name: 'meta_id' })
  metaId: number;

  @Column({ type: 'bigint', name: 'cuenta_id', nullable: true })
  cuentaId: number | null;

  @Column({ type: 'decimal', precision: 18, scale: 2, name: 'monto_aporte' })
  montoAporte: number;

  @Column({ type: 'datetime2', name: 'fecha_aporte' })
  fechaAporte: Date;

  @Column({ type: 'nvarchar', length: 500, nullable: true })
  notas: string | null;
}

