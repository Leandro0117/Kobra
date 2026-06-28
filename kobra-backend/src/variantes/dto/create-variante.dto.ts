import { IsNumber, IsOptional, IsPositive, IsString } from 'class-validator';

export class CreateVarianteDto {
  @IsString()
  nombre: string;

  @IsNumber()
  @IsPositive()
  precio: number;

  // Lo que cuesta producir/comprar esta variante; opcional, para estimar ganancia.
  @IsOptional()
  @IsNumber()
  @IsPositive()
  costo?: number;
}
