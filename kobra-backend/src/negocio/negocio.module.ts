import { Module } from '@nestjs/common';
import { NegocioService } from './negocio.service';
import { NegocioController } from './negocio.controller';

@Module({
  controllers: [NegocioController],
  providers: [NegocioService],
})
export class NegocioModule {}
