import { IsNumber, IsPositive, IsString } from 'class-validator';

export class CreateVarianteDto {
  @IsString()
  nombre: string;

  @IsNumber()
  @IsPositive()
  precio: number;
}
