import { IsNumber, IsOptional, IsPositive, IsString } from 'class-validator';

export class CreateInsumoDto {
  @IsString()
  nombre: string;

  @IsOptional()
  @IsString()
  unidad?: string;

  @IsOptional()
  @IsNumber()
  @IsPositive()
  precio?: number;
}
