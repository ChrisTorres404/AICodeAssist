// Seeder Module
// Purpose: module that provides the seeder to the application context.
//
// No entities are registered with forFeature() because the seeds talk to the
// database through the shared QueryRunner rather than through repositories.

import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { SeederService } from './seeder.service';

@Module({
  imports: [TypeOrmModule.forFeature([])],
  providers: [SeederService],
  exports: [SeederService],
})
export class SeederModule {}
