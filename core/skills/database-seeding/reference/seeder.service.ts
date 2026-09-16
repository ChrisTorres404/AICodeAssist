// Seeder Service
// Purpose: transactional entry point for seeding the platform database.
//
// One transaction wraps every seed, so a failure anywhere leaves the database
// exactly as it was. Seed order is explicit: the arrays below are the contract,
// never the directory listing.

import { Injectable, Logger } from '@nestjs/common';
import { DataSource, QueryRunner } from 'typeorm';

export interface SeederOptions {
  environment: 'development' | 'staging' | 'production';
  force?: boolean; // Re-seed even if data exists
  verbose?: boolean; // Detailed logging
}

/** Row shape returned by the information_schema lookup in verifyDatabase(). */
interface SchemaRow {
  schema_name: string;
}

/** Row shape returned by the RLS verification function. */
interface RlsRow {
  schema_name: string;
  table_name: string;
  rls_enabled: boolean;
  rls_forced: boolean;
}

/** Signature every seed file's default export must satisfy. */
type SeedFunction = (
  queryRunner: QueryRunner,
  options: SeederOptions,
) => Promise<void>;

const RULE = '========================================';

/** Schemas the seeds write into. Missing any of them means migrations did not run. */
const REQUIRED_SCHEMAS = [
  'auth',
  'rbac',
  'audit',
  'webhooks',
  'org',
  'notifications',
  'settings',
];

/** System seeds. Required in every environment, including production. */
const SYSTEM_SEEDS = [
  './001-system/001-platform-tenant.seed',
  './001-system/002-platform-owner.seed',
  './001-system/003-system-roles.seed',
  './001-system/004-audit-retention.seed',
  // Diagnostic test-suite definitions
  './001-system/005-test-suite-definitions.seed',
  // Notification system (events, templates, providers)
  './002-notifications/001-notification-events.seed',
  './002-notifications/002-notification-templates.seed',
  './002-notifications/003-notification-providers.seed',
];

/** Development-only seeds. Never referenced outside the development branch. */
const DEV_TEST_SEEDS = [
  './003-dev-test/001-test-tenants.seed',
  './003-dev-test/000-tenant-roles.seed', // Roles for test tenants BEFORE users
  './003-dev-test/002-test-users.seed',
  './003-dev-test/003-user-role-assignments.seed', // Every user gets a role
  './003-dev-test/004-test-organizations.seed', // Hierarchical organization structure
  './003-dev-test/005-test-webhooks.seed', // Webhook endpoints for testing
];

@Injectable()
export class SeederService {
  private readonly logger = new Logger(SeederService.name);
  private queryRunner: QueryRunner;

  constructor(private dataSource: DataSource) {}

  /**
   * Main seeding entry point.
   * Runs the seeds appropriate to the requested environment, inside a single
   * transaction that is rolled back on any error.
   */
  async seed(options: SeederOptions): Promise<void> {
    this.queryRunner = this.dataSource.createQueryRunner();
    await this.queryRunner.connect();
    await this.queryRunner.startTransaction();

    try {
      this.logger.log(RULE);
      this.logger.log('DATABASE SEEDING');
      this.logger.log(`   Environment: ${options.environment.toUpperCase()}`);
      this.logger.log(`   Force: ${options.force ? 'YES' : 'NO'}`);
      this.logger.log(`   Verbose: ${options.verbose ? 'YES' : 'NO'}`);
      this.logger.log(RULE);
      this.logger.log('');

      // PHASE 1: System seeds (ALL ENVIRONMENTS)
      this.logger.log('PHASE 1: System Seeds');
      this.logger.log('   (Required for the platform to function)');
      this.logger.log('');
      await this.runSystemSeeds(options);

      // PHASE 2: Environment-specific seeds
      if (options.environment === 'development') {
        this.logger.log('');
        this.logger.log('PHASE 2: Development Seeds');
        this.logger.log('   (Test tenants and sample data)');
        this.logger.log('');
        await this.runDevTestSeeds(options);
      } else if (options.environment === 'staging') {
        this.logger.log('');
        this.logger.log('PHASE 2: Staging Seeds');
        this.logger.log('   (Minimal test data for verification)');
        this.logger.log('');
        // Staging may carry one test tenant for verification:
        // await this.runStagingSeeds(options);
      }
      // Production: no additional seeds. Tenants are created through the API.

      await this.queryRunner.commitTransaction();

      this.logger.log('');
      this.logger.log(RULE);
      this.logger.log('SEEDING COMPLETED SUCCESSFULLY');
      this.logger.log(RULE);

      if (options.environment === 'development') {
        this.logger.log('');
        this.logger.log('Test credentials:');
        this.logger.log(
          '   See: src/database/seeds/003-dev-test/TEST-CREDENTIALS.md',
        );
        this.logger.log('');
        this.logger.log('Platform owner login:');
        this.logger.log('   Email:    $SEED_OWNER_EMAIL');
        this.logger.log('   Password: $SEED_OWNER_PASSWORD');
      }
    } catch (error) {
      await this.queryRunner.rollbackTransaction();
      this.logger.error('Seeding failed:', error);
      throw error;
    } finally {
      await this.queryRunner.release();
    }
  }

  /**
   * Run system seeds (required for all environments).
   */
  private async runSystemSeeds(options: SeederOptions): Promise<void> {
    await this.runSeeds(SYSTEM_SEEDS, options);
  }

  /**
   * Run dev/test seeds (development only).
   */
  private async runDevTestSeeds(options: SeederOptions): Promise<void> {
    await this.runSeeds(DEV_TEST_SEEDS, options);
  }

  /**
   * Load and execute each seed module in the given order. Any failure aborts the
   * run so the caller's transaction is rolled back.
   */
  private async runSeeds(
    seedPaths: string[],
    options: SeederOptions,
  ): Promise<void> {
    for (const seedPath of seedPaths) {
      try {
        // require keeps CommonJS compatibility with ts-node
        // eslint-disable-next-line @typescript-eslint/no-require-imports
        const seedModule = require(seedPath) as { default?: SeedFunction };
        const seedFunction = seedModule.default;

        if (typeof seedFunction === 'function') {
          if (options.verbose) {
            this.logger.log(`   -> ${seedPath}`);
          }
          await seedFunction(this.queryRunner, options);
        } else {
          this.logger.warn(`Seed ${seedPath} does not export default function`);
        }
      } catch (error) {
        this.logger.error(`Failed to run seed ${seedPath}:`, error);
        throw error;
      }
    }
  }

  /**
   * Verify the database connection and schema.
   * Returns false when a required schema is missing, which means migrations have
   * not been run. A table without RLS is reported but does not fail the check.
   */
  async verifyDatabase(): Promise<boolean> {
    try {
      // Check that the required schemas exist
      const schemas: SchemaRow[] = await this.dataSource.query(
        `
        SELECT schema_name
        FROM information_schema.schemata
        WHERE schema_name = ANY($1)
        ORDER BY schema_name
      `,
        [REQUIRED_SCHEMAS],
      );

      const existingSchemas = schemas.map((s) => s.schema_name);

      for (const schema of REQUIRED_SCHEMAS) {
        if (!existingSchemas.includes(schema)) {
          this.logger.error(`Required schema "${schema}" not found!`);
          this.logger.error(
            'Run database migrations first: npm run migration:run',
          );
          return false;
        }
      }

      // Check that row-level security is enabled everywhere it should be
      const rlsCheck: RlsRow[] = await this.dataSource.query(`
        SELECT * FROM auth.verify_rls_enabled()
        WHERE rls_enabled = false OR rls_forced = false
        LIMIT 5
      `);

      if (rlsCheck.length > 0) {
        this.logger.warn('Some tables do not have RLS enabled:');
        for (const table of rlsCheck) {
          this.logger.warn(
            `   - ${table.schema_name}.${table.table_name} (enabled: ${table.rls_enabled}, forced: ${table.rls_forced})`,
          );
        }
      }

      return true;
    } catch (error) {
      this.logger.error('Database verification failed:', error);
      return false;
    }
  }
}
