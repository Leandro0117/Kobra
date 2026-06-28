import { IsOptional, IsString } from 'class-validator';

export class CreateInsumoDto {
  @IsString()
  nombre: string;

  @IsOptional()
  @IsString()
  unidad?: string;
}
