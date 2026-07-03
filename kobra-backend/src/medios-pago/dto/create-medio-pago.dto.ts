import { IsString, MinLength } from 'class-validator';

export class CreateMedioPagoDto {
  @IsString()
  @MinLength(1)
  nombre: string;
}
