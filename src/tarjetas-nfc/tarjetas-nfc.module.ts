import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { TarjetasNfcService } from './tarjetas-nfc.service';
import { TarjetasNfcController } from './tarjetas-nfc.controller';

@Module({
  imports: [TypeOrmModule.forFeature([])],
  controllers: [TarjetasNfcController],
  providers: [TarjetasNfcService],
})
export class TarjetasNfcModule {}


