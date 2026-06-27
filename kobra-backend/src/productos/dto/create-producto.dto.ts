import { IsString } from 'class-validator';

export class CreateProductoDto {
  @IsString()
  nombre: string;
}
