import { IsInt, IsNumber, IsPositive } from 'class-validator';

export class RegistrarPagoDto {
  @IsNumber()
  @IsPositive()
  monto: number;

  @IsInt()
  medioPagoId: number;
}
