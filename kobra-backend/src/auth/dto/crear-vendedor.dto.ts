import { IsEmail, IsString, MinLength } from 'class-validator';

export class CrearVendedorDto {
  @IsString()
  nombre: string;

  @IsEmail()
  email: string;

  @IsString()
  @MinLength(6)
  password: string;
}
