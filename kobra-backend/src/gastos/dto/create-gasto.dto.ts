import { Type } from 'class-transformer';
import {
  ArrayMinSize,
  IsArray,
  IsEnum,
  IsInt,
  IsPositive,
  ValidateNested,
} from 'class-validator';
import { CategoriaGasto } from '@prisma/client';

export class DetalleGastoInputDto {
  @IsInt()
  insumoId: number;

  @IsPositive()
  cantidad: number;

  // A diferencia de las ventas, aquí no hay un precio "oficial" guardado en
  // el catálogo: es lo que efectivamente se pagó en esa compra, y varía de
  // una compra a otra. Lo ingresa quien registra el gasto.
  @IsPositive()
  precioUnitario: number;
}

export class CreateGastoDto {
  @IsInt()
  proveedorId: number;

  @IsEnum(CategoriaGasto)
  categoria: CategoriaGasto;

  @IsArray()
  @ArrayMinSize(1)
  @ValidateNested({ each: true })
  @Type(() => DetalleGastoInputDto)
  detalles: DetalleGastoInputDto[];
}
