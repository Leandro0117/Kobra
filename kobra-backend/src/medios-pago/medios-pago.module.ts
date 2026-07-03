import { Module } from '@nestjs/common';
import { MediosPagoService } from './medios-pago.service';
import { MediosPagoController } from './medios-pago.controller';

@Module({
  controllers: [MediosPagoController],
  providers: [MediosPagoService],
})
export class MediosPagoModule {}
