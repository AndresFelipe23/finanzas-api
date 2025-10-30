import { Entity, Column, PrimaryGeneratedColumn, CreateDateColumn } from 'typeorm';

@Entity('categorias')
export class Categoria {
  @PrimaryGeneratedColumn({ type: 'bigint' })
  id: number;

  @Column({ type: 'bigint', nullable: true, name: 'usuario_id' })
  usuarioId: number;

  @Column({ type: 'nvarchar', length: 100 })
  nombre: string;

  @Column({ type: 'nvarchar', length: 50, nullable: true })
  icono: string;

  @Column({ type: 'nvarchar', length: 7, nullable: true })
  color: string;

  @Column({ type: 'nvarchar', length: 20 })
  tipo: 'INGRESO' | 'GASTO' | 'AMBOS';

  @Column({ type: 'bit', default: true })
  activo: boolean;

  @CreateDateColumn({ type: 'datetime2', name: 'fecha_creacion' })
  fechaCreacion: Date;
}

