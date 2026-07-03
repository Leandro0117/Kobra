import { Type } from 'class-transformer';
import {
  ArrayMinSize,
  IsArray,
  IsEnum,
  IsInt,
  IsNumber,
  IsOptional,
  IsPositive,
  Min,
  ValidateNested,
} from 'class-validator';
import { EstadoVenta, TipoDescuento } from '@prisma/client';

export class DetalleVentaInputDto {
  @IsInt()
  varianteId: number;

  @IsPositive()
  cantidad: number;
}

export class CreateVentaDto {
  @IsInt()
  clienteId: number;

  @IsOptional()
  @IsEnum(EstadoVenta)
  estado?: EstadoVenta;

  @IsOptional()
  @IsNumber()
  @Min(0)
  descuento?: number;

  @IsOptional()
  @IsEnum(TipoDescuento)
  tipoDescuento?: TipoDescuento;

  @IsArray()
  @ArrayMinSize(1)
  @ValidateNested({ each: true })
  @Type(() => DetalleVentaInputDto)
  detalles: DetalleVentaInputDto[];
}
