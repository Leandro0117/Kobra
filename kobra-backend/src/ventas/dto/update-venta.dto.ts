import { Type } from 'class-transformer';
import {
  ArrayMinSize,
  IsArray,
  IsEnum,
  IsInt,
  IsNumber,
  IsOptional,
  Min,
  ValidateNested,
} from 'class-validator';
import { TipoDescuento } from '@prisma/client';
import { DetalleVentaInputDto } from './create-venta.dto';

export class UpdateVentaDto {
  @IsInt()
  @IsOptional()
  clienteId?: number;

  @IsInt()
  @IsOptional()
  medioPagoId?: number;

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
