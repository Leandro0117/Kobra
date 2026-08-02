import { Type } from 'class-transformer';
import { IsDateString, IsEnum, IsInt, IsOptional } from 'class-validator';
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

  @IsOptional()
  @IsDateString()
  desde?: string;

  @IsOptional()
  @IsDateString()
  hasta?: string;
}
