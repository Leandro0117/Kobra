import { IsEmail, IsOptional, IsString, MinLength } from 'class-validator';

export class ActualizarVendedorDto {
  @IsString()
  @IsOptional()
  nombre?: string;

  @IsEmail()
  @IsOptional()
  email?: string;

  @IsString()
  @MinLength(6)
  @IsOptional()
  password?: string;
}
