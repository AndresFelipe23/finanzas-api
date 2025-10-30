import { Module } from '@nestjs/common';
import { DispositivosNfcService } from './dispositivos-nfc.service';
import { DispositivosNfcController } from './dispositivos-nfc.controller';

@Module({
  controllers: [DispositivosNfcController],
  providers: [DispositivosNfcService],
  exports: [DispositivosNfcService],
})
export class DispositivosNfcModule {}


