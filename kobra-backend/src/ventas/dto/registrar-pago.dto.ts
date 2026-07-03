import { IsInt, IsNumber, IsOptional, IsPositive } from 'class-validator';

export class RegistrarPagoDto {
  @IsNumber()
  @IsPositive()
  monto: number;

  @IsOptional()
  @IsInt()
  medioPagoId?: number;
}
