import { Type } from 'class-transformer';
import {
  ArrayMinSize,
  IsArray,
  IsEnum,
  IsInt,
  IsOptional,
  IsPositive,
  IsString,
  ValidateNested,
} from 'class-validator';
import { CategoriaGasto } from '@prisma/client';

export class DetalleGastoInputDto {
  @IsOptional()
  @IsInt()
  insumoId?: number;

  @IsOptional()
  @IsString()
  concepto?: string;

  @IsPositive()
  cantidad: number;

  // Lo que efectivamente se pagó en esa compra (varía por transacción).
  @IsPositive()
  precioUnitario: number;
}

export class CreateGastoDto {
  @IsOptional()
  @IsInt()
  proveedorId?: number;

  @IsEnum(CategoriaGasto)
  categoria: CategoriaGasto;

  @IsArray()
  @ArrayMinSize(1)
  @ValidateNested({ each: true })
  @Type(() => DetalleGastoInputDto)
  detalles: DetalleGastoInputDto[];
}
