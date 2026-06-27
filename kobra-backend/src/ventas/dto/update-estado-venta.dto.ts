import { IsEnum } from 'class-validator';
import { EstadoVenta } from '@prisma/client';

export class UpdateEstadoVentaDto {
  @IsEnum(EstadoVenta)
  estado: EstadoVenta;
}
