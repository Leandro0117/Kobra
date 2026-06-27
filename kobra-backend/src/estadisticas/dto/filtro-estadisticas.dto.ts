import { IsISO8601, IsOptional } from 'class-validator';

export class FiltroEstadisticasDto {
  @IsOptional()
  @IsISO8601()
  desde?: string;

  @IsOptional()
  @IsISO8601()
  hasta?: string;
}
