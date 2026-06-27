import { Type } from 'class-transformer';
import { IsEnum, IsInt, IsOptional } from 'class-validator';
import { EstadoVenta } from '@prisma/client';

export class FiltroVentasDto {
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  vendedorId?: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  clienteId?: number;

  @IsOptional()
  @IsEnum(EstadoVenta)
  estado?: EstadoVenta;
}
