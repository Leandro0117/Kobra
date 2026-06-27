import { Module } from '@nestjs/common';
import { VariantesService } from './variantes.service';
import { VariantesController } from './variantes.controller';

@Module({
  controllers: [VariantesController],
  providers: [VariantesService],
})
export class VariantesModule {}
