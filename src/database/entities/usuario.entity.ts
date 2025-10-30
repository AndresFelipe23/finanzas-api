import { Entity, Column, PrimaryGeneratedColumn, CreateDateColumn, UpdateDateColumn } from 'typeorm';

@Entity('usuarios')
export class Usuario {
  @PrimaryGeneratedColumn({ type: 'bigint' })
  id: number;

  @Column({ type: 'nvarchar', length: 100 })
  nombre: string;

  @Column({ type: 'nvarchar', length: 255, unique: true })
  email: string;

  @Column({ type: 'nvarchar', length: 255, name: 'password_hash' })
  passwordHash: string;

  @Column({ type: 'nvarchar', length: 20, nullable: true })
  telefono: string;

  @Column({ type: 'datetime2', nullable: true, name: 'fecha_nacimiento' })
  fechaNacimiento: Date;

  @Column({ type: 'nvarchar', length: 10, default: 'COP', name: 'moneda_predeterminada' })
  monedaPredeterminada: string;

  @Column({ type: 'bit', default: true })
  activo: boolean;

  @CreateDateColumn({ type: 'datetime2', name: 'fecha_creacion' })
  fechaCreacion: Date;

  @UpdateDateColumn({ type: 'datetime2', name: 'fecha_actualizacion' })
  fechaActualizacion: Date;
}

