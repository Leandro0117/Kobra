import { IsOptional, IsString } from 'class-validator';

export class CreateProveedorDto {
  @IsString()
  nombre: string;

  @IsOptional()
  @IsString()
  telefono?: string;
}
