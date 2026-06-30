import { IsEnum, IsNumber, IsOptional, IsPositive, IsString } from 'class-validator';
import { UnidadInsumo } from '@prisma/client';

export class CreateInsumoDto {
  @IsString()
  nombre: string;

  @IsOptional()
  @IsEnum(UnidadInsumo)
  unidad?: UnidadInsumo;

  @IsOptional()
  @IsNumber()
  @IsPositive()
  precio?: number;
}
