import { Type } from 'class-transformer';
import { ArrayMinSize, IsArray, IsInt, IsOptional, ValidateNested } from 'class-validator';
import { DetalleVentaInputDto } from './create-venta.dto';

export class UpdateVentaDto {
  @IsInt()
  @IsOptional()
  clienteId?: number;

  @IsArray()
  @ArrayMinSize(1)
  @ValidateNested({ each: true })
  @Type(() => DetalleVentaInputDto)
  detalles: DetalleVentaInputDto[];
}
