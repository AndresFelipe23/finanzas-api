import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { PagosNfcService } from './pagos-nfc.service';
import { PagosNfcController } from './pagos-nfc.controller';

@Module({
  imports: [TypeOrmModule.forFeature([])],
  controllers: [PagosNfcController],
  providers: [PagosNfcService],
})
export class PagosNfcModule {}


