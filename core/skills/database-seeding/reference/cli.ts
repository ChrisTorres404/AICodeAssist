#!/usr/bin/env ts-node
// Seeder CLI
// Purpose: command-line interface for running database seeds.
//
//   npm run seed:dev
//   npm run seed:dev -- --verbose
//   npm run seed:production -- --confirm
//
// Exit codes: 0 seeded, 1 refused or failed.

import { NestFactory } from '@nestjs/core';
import { AppModule } from '../../app.module';
import { SeederService, SeederOptions } from './seeder.service';

async function bootstrap(): Promise<void> {
  // Parse command-line arguments
  const args = process.argv.slice(2);
  const environment = (process.env.NODE_ENV || 'development') as
    | 'development'
    | 'staging'
    | 'production';

  // Parse options
  const options: SeederOptions = {
    environment,
    force: args.includes('--force'),
    verbose: args.includes('--verbose') || args.includes('-v'),
  };

  // Production safety check
  if (environment === 'production' && !args.includes('--confirm')) {
    console.error('');
    console.error('ERROR: Production seeding requires explicit confirmation');
    console.error('');
    console.error(
      'Production seeding is a destructive-by-mistake operation that should only be run:',
    );
    console.error('  1. During initial deployment');
    console.error('  2. After a complete database restoration');
    console.error('  3. With explicit approval from the service owner');
    console.error('');
    console.error('To confirm, run:');
    console.error('  npm run seed:production -- --confirm');
    console.error('');
    console.error(
      'WARNING: this will create system-level data in PRODUCTION.',
    );
    console.error('');
    process.exit(1);
  }

  console.log('');
  console.log('Starting seeder...');
  console.log('');

  // Create the application context (no HTTP server)
  const app = await NestFactory.createApplicationContext(AppModule, {
    logger: ['error', 'warn', 'log'],
  });

  try {
    const seederService = app.get(SeederService);

    // Verify the database before seeding
    console.log('Verifying database schema...');
    const isValid = await seederService.verifyDatabase();

    if (!isValid) {
      console.error('');
      console.error('Database verification failed.');
      console.error('   Make sure you have run migrations first:');
      console.error('   npm run migration:run');
      console.error('');
      await app.close();
      process.exit(1);
    }

    console.log('Database schema verified');
    console.log('');

    // Run seeds
    await seederService.seed(options);

    await app.close();
    process.exit(0);
  } catch (error) {
    console.error('');
    console.error('Seeding failed:', error);
    console.error('');
    await app.close();
    process.exit(1);
  }
}

void bootstrap();
