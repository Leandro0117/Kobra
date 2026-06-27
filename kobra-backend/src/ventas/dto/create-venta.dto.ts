import { Type } from 'class-transformer';
import {
  ArrayMinSize,
  IsArray,
  IsEnum,
  IsInt,
  IsOptional,
  IsPositive,
  ValidateNested,
} from 'class-validator';
import { EstadoVenta } from '@prisma/client';

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

  @IsArray()
  @ArrayMinSize(1)
  @ValidateNested({ each: true })
  @Type(() => DetalleVentaInputDto)
  detalles: DetalleVentaInputDto[];
}
