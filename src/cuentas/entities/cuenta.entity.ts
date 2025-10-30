import { Entity, Column, PrimaryGeneratedColumn, CreateDateColumn } from 'typeorm';

@Entity('cuentas')
export class Cuenta {
  @PrimaryGeneratedColumn({ type: 'bigint' })
  id: number;

  @Column({ type: 'bigint', name: 'usuario_id' })
  usuarioId: number;

  @Column({ type: 'nvarchar', length: 100 })
  nombre: string;

  @Column({ type: 'nvarchar', length: 30 })
  tipo: 'BANCARIA' | 'EFECTIVO' | 'TARJETA_CREDITO' | 'TARJETA_DEBITO' | 'DIGITAL' | 'AHORRO' | 'INVERSION';

  @Column({ type: 'nvarchar', length: 10, default: 'COP' })
  moneda: string;

  @Column({ type: 'decimal', precision: 18, scale: 2, default: 0, name: 'saldo_inicial' })
  saldoInicial: number;

  @Column({ type: 'nvarchar', length: 7, nullable: true })
  color: string;

  @Column({ type: 'nvarchar', length: 50, nullable: true })
  icono: string;

  @Column({ type: 'nvarchar', length: 500, nullable: true })
  descripcion: string;

  @Column({ type: 'bit', default: true })
  activa: boolean;

  @CreateDateColumn({ type: 'datetime2', name: 'fecha_creacion' })
  fechaCreacion: Date;
}

