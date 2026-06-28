import { Type } from 'class-transformer';
import { IsEnum, IsInt, IsOptional } from 'class-validator';
import { CategoriaGasto } from '@prisma/client';

export class FiltroGastosDto {
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  proveedorId?: number;

  @IsOptional()
  @IsEnum(CategoriaGasto)
  categoria?: CategoriaGasto;
}
