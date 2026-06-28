import { IsNotEmpty, IsOptional, IsString } from 'class-validator';

export class UpsertNegocioDto {
  @IsString()
  @IsNotEmpty()
  nombre: string;

  @IsOptional()
  @IsString()
  direccion?: string;

  @IsOptional()
  @IsString()
  telefono?: string;

  @IsString()
  @IsNotEmpty()
  moneda: string;
}
