---
name: nestjs-patterns
description: NestJS architecture patterns for modules, controllers, providers, DTO validation, guards, interceptors, entities, repositories, config, error handling, and testing in production-grade TypeScript backends. Use when building or reviewing a NestJS backend — modules, providers, DTO validation, guards, interceptors, query builders, or service-layer transactions.
---

# NestJS Development Patterns

Production-grade NestJS patterns for modular TypeScript backends, drawn from
patterns that survived contact with a real PostgreSQL-backed API.

## When to Activate

- Building NestJS APIs or services
- Structuring modules, controllers, and providers
- Adding DTO validation, guards, interceptors, or exception filters
- Configuring environment-aware settings and database integrations
- Writing repository/query-builder code or multi-table transactions
- Designing entities with a dual integer-id / external-uuid identity scheme
- Testing NestJS units or HTTP endpoints

## Contents

1. [Project Structure](#project-structure)
2. [Module Structure](#module-structure)
3. [Bootstrap and Global Validation](#bootstrap-and-global-validation)
4. [Modules, Controllers, and Providers](#modules-controllers-and-providers)
5. [Controller Patterns](#controller-patterns)
6. [Service Patterns](#service-patterns)
7. [Guard Patterns](#guard-patterns)
8. [DTO Patterns](#dto-patterns)
9. [Entity Patterns](#entity-patterns)
10. [Repository Patterns](#repository-patterns)
11. [Error Handling](#error-handling)
12. [Configuration](#configuration)
13. [Persistence and Transactions](#persistence-and-transactions)
14. [Testing Patterns](#testing-patterns)
15. [Production Defaults](#production-defaults)
16. [Review Checklist](#review-checklist)

## Project Structure

```text
src/
├── app.module.ts
├── main.ts
├── common/
│   ├── filters/
│   ├── guards/
│   ├── interceptors/
│   └── pipes/
├── config/
│   ├── configuration.ts
│   └── validation.ts
├── modules/
│   ├── auth/
│   │   ├── auth.controller.ts
│   │   ├── auth.module.ts
│   │   ├── auth.service.ts
│   │   ├── dto/
│   │   ├── guards/
│   │   └── strategies/
│   └── users/
│       ├── dto/
│       ├── entities/
│       ├── users.controller.ts
│       ├── users.module.ts
│       └── users.service.ts
└── prisma/ or database/
```

- Keep domain code inside feature modules.
- Put cross-cutting filters, decorators, guards, and interceptors in `common/`.
- Keep DTOs close to the module that owns them.

An ORM-centric variant that hoists entities to a shared directory is documented in
[typeorm-patterns](../typeorm-patterns/SKILL.md); either layout works as long as it is
applied consistently.

Scaffolding with the CLI keeps the layout honest:

```bash
npx nest generate module modules/orders
npx nest generate controller modules/orders --flat
npx nest generate service modules/orders --flat
```

## Module Structure

### Feature Module Pattern

Each feature gets its own module with controller, service, and DTOs:

```typescript
// orders/orders.module.ts
import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { OrdersController } from './orders.controller';
import { OrdersService } from './orders.service';
import { Order } from '../../entities/order.entity';
import { OrderItem } from '../../entities/order-item.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([Order, OrderItem]),
  ],
  controllers: [OrdersController],
  providers: [OrdersService],
  exports: [OrdersService],  // Export if other modules need it
})
export class OrdersModule {}
```

### App Module Pattern

```typescript
// app.module.ts
import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';

// Feature modules
import { CatalogModule } from './modules/catalog/catalog.module';
import { OrdersModule } from './modules/orders/orders.module';
import { CustomersModule } from './modules/customers/customers.module';

// Entities
import { Customer, Order, Product } from './entities';

@Module({
  imports: [
    // Config first - other modules depend on it
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: ['.env', '.env.development'],
    }),

    // Database connection
    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        type: 'postgres',
        host: config.get('DB_HOST', 'localhost'),
        port: config.get('DB_PORT', 5432),
        username: config.get('DB_USER'),
        database: config.get('DB_NAME'),
        entities: [Customer, Order, Product],
        synchronize: config.get('NODE_ENV') !== 'production',
        logging: config.get('NODE_ENV') === 'development',
      }),
    }),

    // Feature modules
    CatalogModule,
    OrdersModule,
    CustomersModule,
  ],
})
export class AppModule {}
```

- Register `ConfigModule` before anything that reads config.
- `synchronize` must be false in production; use migrations instead. See
  [database-migrations](../database-migrations/SKILL.md).

## Bootstrap and Global Validation

```ts
async function bootstrap() {
  const app = await NestFactory.create(AppModule, { bufferLogs: true });

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      transformOptions: { enableImplicitConversion: true },
    }),
  );

  app.useGlobalInterceptors(new ClassSerializerInterceptor(app.get(Reflector)));
  app.useGlobalFilters(new HttpExceptionFilter());

  await app.listen(process.env.PORT ?? 3000);
}
bootstrap();
```

- Always enable `whitelist` and `forbidNonWhitelisted` on public APIs.
- Prefer one global validation pipe instead of repeating validation config per route.

## Modules, Controllers, and Providers

```ts
@Module({
  controllers: [UsersController],
  providers: [UsersService],
  exports: [UsersService],
})
export class UsersModule {}

@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get(':id')
  getById(@Param('id', ParseUUIDPipe) id: string) {
    return this.usersService.getById(id);
  }

  @Post()
  create(@Body() dto: CreateUserDto) {
    return this.usersService.create(dto);
  }
}

@Injectable()
export class UsersService {
  constructor(private readonly usersRepo: UsersRepository) {}

  async create(dto: CreateUserDto) {
    return this.usersRepo.create(dto);
  }
}
```

- Controllers should stay thin: parse HTTP input, call a provider, return response DTOs.
- Put business logic in injectable services, not controllers.
- Export only the providers other modules genuinely need.

## Controller Patterns

### RESTful Controller Pattern

```typescript
// orders/orders.controller.ts
import {
  Controller,
  Get,
  Post,
  Put,
  Param,
  Body,
  Query,
  UseGuards,
  Req,
} from '@nestjs/common';
import { OrdersService } from './orders.service';
import { CreateOrderDto, UpdateOrderStatusDto } from './dto';
import { AuthGuard } from '../../guards/auth.guard';
import { AuthenticatedRequest } from '../../types';

@Controller('api')
export class OrdersController {
  constructor(private readonly ordersService: OrdersService) {}

  // Customer routes - require auth
  @Get('me/orders')
  @UseGuards(AuthGuard)
  async getMyOrders(@Req() req: AuthenticatedRequest) {
    return this.ordersService.findByCustomerId(req.customer.id);
  }

  @Get('me/orders/:uuid')
  @UseGuards(AuthGuard)
  async getMyOrder(
    @Req() req: AuthenticatedRequest,
    @Param('uuid') uuid: string,
  ) {
    return this.ordersService.findByUuidForCustomer(uuid, req.customer.id);
  }

  @Post('orders')
  @UseGuards(AuthGuard)
  async createOrder(
    @Req() req: AuthenticatedRequest,
    @Body() dto: CreateOrderDto,
  ) {
    return this.ordersService.create(req.customer.id, dto);
  }
}
```

### Admin Controller Pattern (Role-Based)

```typescript
// admin/admin.controller.ts
@Controller('api/admin')
@UseGuards(AuthGuard, AdminGuard)  // Stack guards
export class AdminController {
  constructor(
    private readonly ordersService: OrdersService,
    private readonly customersService: CustomersService,
  ) {}

  @Get('dashboard')
  async getDashboard() {
    const [orderStats, customerCount] = await Promise.all([
      this.ordersService.getStats(),
      this.customersService.count(),
    ]);
    return { orders: orderStats, customers: customerCount };
  }

  @Get('orders')
  async getAllOrders(
    @Query('status') status?: string,
    @Query('limit') limit?: number,
    @Query('offset') offset?: number,
  ) {
    return this.ordersService.findAll({ status, limit, offset });
  }

  @Put('orders/:uuid/status')
  async updateOrderStatus(
    @Param('uuid') uuid: string,
    @Body() dto: UpdateOrderStatusDto,
    @Req() req: AuthenticatedRequest,
  ) {
    return this.ordersService.updateStatus(uuid, dto.status, dto.message, req.customer);
  }
}
```

### Response Wrapper Pattern

```typescript
// Consistent response structure
@Get('orders')
async getOrders(@Query() query: ListOrdersDto) {
  const { orders, total } = await this.ordersService.findAll(query);
  return {
    orders,
    total,
    page: query.page || 1,
    limit: query.limit || 20,
  };
}
```

### Route Identifier Choice

| Context | Identifier | Why |
|---|---|---|
| Public URL / API payload | `uuid` | Non-enumerable, safe to expose |
| Foreign keys and joins | `id` (integer) | Narrow, fast to index |
| Log correlation | `uuid` | Stable across environments |
| Internal service calls | `id` (integer) | Already loaded, no extra lookup |

## Service Patterns

### Basic CRUD Service Pattern

```typescript
// orders/orders.service.ts
import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Order } from '../../entities/order.entity';

@Injectable()
export class OrdersService {
  constructor(
    @InjectRepository(Order)
    private readonly orderRepository: Repository<Order>,
  ) {}

  // Find by UUID (external identifier)
  async findByUuid(uuid: string): Promise<Order> {
    const order = await this.orderRepository.findOne({
      where: { uuid },
      relations: ['items', 'customer'],
    });

    if (!order) {
      throw new NotFoundException('Order not found');
    }

    return order;
  }

  // Find by internal ID (for relationships)
  async findById(id: number): Promise<Order> {
    const order = await this.orderRepository.findOne({
      where: { id },
    });

    if (!order) {
      throw new NotFoundException('Order not found');
    }

    return order;
  }

  // List with filters and pagination
  async findAll(options?: {
    status?: string;
    limit?: number;
    offset?: number;
  }): Promise<{ orders: Order[]; total: number }> {
    const query = this.orderRepository
      .createQueryBuilder('order')
      .leftJoinAndSelect('order.customer', 'customer');

    if (options?.status) {
      query.where('order.status = :status', { status: options.status });
    }

    const total = await query.getCount();

    query.orderBy('order.createdAt', 'DESC');

    if (options?.limit) {
      query.take(options.limit);
    }
    if (options?.offset) {
      query.skip(options.offset);
    }

    const orders = await query.getMany();

    return { orders, total };
  }
}
```

### Transaction Pattern

```typescript
// For operations that touch multiple tables
async create(customerId: number, dto: CreateOrderDto): Promise<Order> {
  const queryRunner = this.dataSource.createQueryRunner();
  await queryRunner.connect();
  await queryRunner.startTransaction();

  try {
    // Create order
    const order = queryRunner.manager.create(Order, {
      customerId,
      status: 'pending',
      total: dto.total,
    });
    const savedOrder = await queryRunner.manager.save(order);

    // Create order items
    for (const item of dto.items) {
      const orderItem = queryRunner.manager.create(OrderItem, {
        orderId: savedOrder.id,
        productId: item.productId,
        quantity: item.quantity,
      });
      await queryRunner.manager.save(orderItem);
    }

    await queryRunner.commitTransaction();

    // Return fresh copy with relations
    return this.findByUuid(savedOrder.uuid);

  } catch (error) {
    await queryRunner.rollbackTransaction();
    throw error;
  } finally {
    await queryRunner.release();
  }
}
```

- `release()` belongs in `finally`; a leaked query runner exhausts the pool quietly.
- Do the read-back *after* the commit so callers never see uncommitted state.

### Auto-Generate Number Pattern

```typescript
// Generate sequential numbers like "ORD-<year>-00001"
private async generateOrderNumber(): Promise<string> {
  const year = new Date().getFullYear();
  const count = await this.orderRepository
    .createQueryBuilder('order')
    .where("order.order_number LIKE :pattern", {
      pattern: `ORD-${year}-%`,
    })
    .getCount();

  return `ORD-${year}-${String(count + 1).padStart(5, '0')}`;
}
```

Count-plus-one is racy under concurrency. For anything that must never collide,
back it with a database sequence or a unique index plus a retry.

### Find-Or-Create Pattern

```typescript
// Useful for creating local records on first authentication
async findOrCreate(authUserUuid: string, email: string): Promise<Customer> {
  let customer = await this.customerRepository.findOne({
    where: { authUserUuid },
  });

  if (!customer) {
    // Check if this is the first customer (make them owner)
    const count = await this.customerRepository.count();
    const role = count === 0 ? 'owner' : 'customer';

    customer = this.customerRepository.create({
      authUserUuid,
      email,
      applicationRole: role,
    });
    customer = await this.customerRepository.save(customer);
  }

  return customer;
}
```

## Guard Patterns

### Auth Guard Pattern (External Auth Provider)

```typescript
// guards/auth.guard.ts
import {
  Injectable,
  CanActivate,
  ExecutionContext,
  UnauthorizedException,
} from '@nestjs/common';
import { HttpService } from '@nestjs/axios';
import { ConfigService } from '@nestjs/config';
import { firstValueFrom } from 'rxjs';
import { CustomersService } from '../modules/customers/customers.service';

@Injectable()
export class AuthGuard implements CanActivate {
  private readonly authApiUrl: string;

  constructor(
    private readonly httpService: HttpService,
    private readonly configService: ConfigService,
    private readonly customersService: CustomersService,
  ) {
    this.authApiUrl = this.configService.get('AUTH_API_URL')!;
  }

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();

    // Extract session token from cookie or header
    const sessionToken = this.extractToken(request);
    if (!sessionToken) {
      throw new UnauthorizedException('No session token');
    }

    try {
      // Validate with auth provider
      const response = await firstValueFrom(
        this.httpService.get(`${this.authApiUrl}/api/auth/session`, {
          headers: {
            Cookie: `app-session=${sessionToken}`,
            Authorization: `Bearer ${sessionToken}`,
          },
        }),
      );

      // Attach user info to request
      request.authUser = response.data.user;

      // Find or create local customer record
      request.customer = await this.customersService.findOrCreate(
        response.data.user.id,
        response.data.user.email,
      );

      return true;
    } catch (error) {
      throw new UnauthorizedException('Invalid session');
    }
  }

  private extractToken(request: any): string | null {
    // Try cookie first
    const cookies = request.cookies || {};
    if (cookies['app-session']) {
      return cookies['app-session'];
    }

    // Try Authorization header
    const authHeader = request.headers['authorization'];
    if (authHeader?.startsWith('Bearer ')) {
      return authHeader.slice(7);
    }

    return null;
  }
}
```

Cookie naming convention used throughout these examples: one short application prefix,
then the purpose — `app-session`, `app-refresh`, `app-csrf-token`. Pick the prefix once
per deployment and never mix prefixes across services that share a cookie domain, or the
browser will send two cookies with the same purpose and the server will read the wrong one.

### Role Guard Pattern

```typescript
// guards/admin.guard.ts
import {
  Injectable,
  CanActivate,
  ExecutionContext,
  ForbiddenException,
} from '@nestjs/common';

@Injectable()
export class AdminGuard implements CanActivate {
  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const customer = request.customer;

    if (!customer) {
      throw new ForbiddenException('No customer context');
    }

    if (!['owner', 'admin'].includes(customer.applicationRole)) {
      throw new ForbiddenException('Admin access required');
    }

    return true;
  }
}
```

### Composable Guards Pattern

```typescript
// Stack guards for layered authorization
@Controller('api/admin')
@UseGuards(AuthGuard, AdminGuard)  // Auth first, then role check
export class AdminController {
  // All routes require auth + admin role
}

// Or per-route
@Get('sensitive-data')
@UseGuards(AuthGuard, AdminGuard, AuditGuard)
async getSensitiveData() {}
```

Guards run left to right. A role guard that reads `request.customer` is only correct if
the auth guard that populates it is listed first.

## Auth, Guards, and Request Context

```ts
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('admin')
@Get('admin/report')
getAdminReport(@Req() req: AuthenticatedRequest) {
  return this.reportService.getForUser(req.user.id);
}
```

- Keep auth strategies and guards module-local unless they are truly shared.
- Encode coarse access rules in guards, then do resource-specific authorization in services.
- Prefer explicit request types for authenticated request objects.

## DTOs and Validation

```ts
export class CreateUserDto {
  @IsEmail()
  email!: string;

  @IsString()
  @Length(2, 80)
  name!: string;

  @IsOptional()
  @IsEnum(UserRole)
  role?: UserRole;
}
```

- Validate every request DTO with `class-validator`.
- Use dedicated response DTOs or serializers instead of returning ORM entities directly.
- Avoid leaking internal fields such as password hashes, tokens, or audit columns.

## DTO Patterns

### Create DTO Pattern

```typescript
// dto/create-order.dto.ts
import {
  IsString,
  IsNumber,
  IsArray,
  IsOptional,
  IsDateString,
  ValidateNested,
  Min,
  MaxLength,
} from 'class-validator';
import { Type } from 'class-transformer';

export class CreateOrderItemDto {
  @IsString()
  productUuid: string;

  @IsNumber()
  @Min(1)
  quantity: number;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  notes?: string;
}

export class CreateOrderDto {
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CreateOrderItemDto)
  items: CreateOrderItemDto[];

  @IsOptional()
  @IsString()
  @MaxLength(1000)
  deliveryAddress?: string;

  @IsOptional()
  @IsDateString()
  deliveryDate?: string;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  specialInstructions?: string;
}
```

`@ValidateNested({ each: true })` without `@Type(() => ...)` silently validates nothing.
The pair is mandatory for arrays of objects.

### Update DTO Pattern (Partial)

```typescript
// dto/update-order.dto.ts
import { PartialType, PickType } from '@nestjs/mapped-types';
import { CreateOrderDto } from './create-order.dto';

// Only allow updating certain fields
export class UpdateOrderDto extends PartialType(
  PickType(CreateOrderDto, ['deliveryAddress', 'deliveryDate', 'specialInstructions'])
) {}
```

### Query DTO Pattern

```typescript
// dto/list-orders.dto.ts
import { IsOptional, IsNumber, IsString, IsIn, Min, Max } from 'class-validator';
import { Type } from 'class-transformer';

export class ListOrdersDto {
  @IsOptional()
  @IsString()
  @IsIn(['pending', 'confirmed', 'in_progress', 'ready', 'delivered', 'cancelled'])
  status?: string;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(1)
  @Max(100)
  limit?: number = 20;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  offset?: number = 0;
}
```

Query strings are always strings. Without `@Type(() => Number)` the `@IsNumber()` check
fails for every request that supplies the parameter.

## Entity Patterns

Entity-level gotchas — nullable columns, reflected metadata, `null` versus `undefined` —
are covered in depth in [typeorm-patterns](../typeorm-patterns/SKILL.md). The patterns
below are the shapes those rules produce.

### Base Entity Pattern

```typescript
// entities/base.entity.ts
import {
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  Generated,
} from 'typeorm';

export abstract class BaseEntity {
  @PrimaryGeneratedColumn({ type: 'bigint' })
  id: number;

  @Column({ type: 'uuid', unique: true })
  @Generated('uuid')
  uuid: string;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}
```

This is the dual-id pattern: an integer `id` for internal joins, a `uuid` for URLs and
API payloads. A `bigint` primary key arrives from the PostgreSQL driver as a **string**,
so normalize with `Number(...)` before using it as a `Map`/`Set` key or comparing it
strictly against a number.

### Entity with Relationships

```typescript
// entities/order.entity.ts
import { Entity, Column, ManyToOne, OneToMany, JoinColumn } from 'typeorm';
import { BaseEntity } from './base.entity';
import { Customer } from './customer.entity';
import { OrderItem } from './order-item.entity';

export type OrderStatus = 'pending' | 'confirmed' | 'in_progress' | 'ready' | 'delivered' | 'cancelled';

@Entity({ schema: 'myschema', name: 'orders' })
export class Order extends BaseEntity {
  @Column({ name: 'order_number', length: 20, unique: true })
  orderNumber: string;

  @Column({ name: 'customer_id', type: 'bigint' })
  customerId: number;

  @ManyToOne(() => Customer, (customer) => customer.orders)
  @JoinColumn({ name: 'customer_id' })
  customer: Customer;

  @Column({ length: 20, default: 'pending' })
  status: OrderStatus;

  @Column({ type: 'decimal', precision: 10, scale: 2 })
  total: number;

  // Optional fields - use ? syntax
  @Column({ name: 'delivery_date', type: 'timestamptz', nullable: true })
  deliveryDate?: Date;

  @Column({ type: 'text', nullable: true })
  notes?: string;

  // One-to-many with cascade
  @OneToMany(() => OrderItem, (item) => item.order, { cascade: true })
  items: OrderItem[];
}
```

### Entity Type Exports Pattern

```typescript
// entities/index.ts
// Export entities
export { Customer } from './customer.entity';
export { Order } from './order.entity';
export { OrderItem } from './order-item.entity';
export { Product } from './product.entity';

// Export types
export type { OrderStatus } from './order.entity';
export type { CustomerRole } from './customer.entity';
```

## Repository Patterns

### Query Builder Pattern

```typescript
// Complex queries with QueryBuilder
async findOrdersWithFilters(filters: {
  customerId?: number;
  status?: string;
  dateFrom?: Date;
  dateTo?: Date;
  search?: string;
}): Promise<Order[]> {
  const query = this.orderRepository
    .createQueryBuilder('order')
    .leftJoinAndSelect('order.items', 'items')
    .leftJoinAndSelect('items.product', 'product')
    .leftJoinAndSelect('order.customer', 'customer');

  if (filters.customerId) {
    query.andWhere('order.customer_id = :customerId', {
      customerId: filters.customerId,
    });
  }

  if (filters.status) {
    query.andWhere('order.status = :status', { status: filters.status });
  }

  if (filters.dateFrom) {
    query.andWhere('order.created_at >= :dateFrom', {
      dateFrom: filters.dateFrom,
    });
  }

  if (filters.dateTo) {
    query.andWhere('order.created_at <= :dateTo', {
      dateTo: filters.dateTo,
    });
  }

  if (filters.search) {
    query.andWhere(
      '(order.order_number ILIKE :search OR customer.email ILIKE :search)',
      { search: `%${filters.search}%` },
    );
  }

  return query.orderBy('order.createdAt', 'DESC').getMany();
}
```

- Use `andWhere` for every optional filter. A stray `where` later in the chain resets the
  whole predicate and silently widens the query.
- Always bind parameters (`:name`) — never interpolate user input into the SQL string.

### Aggregation Pattern

```typescript
// Get statistics
async getOrderStats(): Promise<{
  total: number;
  pending: number;
  completed: number;
  revenue: number;
}> {
  const stats = await this.orderRepository
    .createQueryBuilder('order')
    .select('COUNT(*)', 'total')
    .addSelect("COUNT(*) FILTER (WHERE status = 'pending')", 'pending')
    .addSelect("COUNT(*) FILTER (WHERE status = 'delivered')", 'completed')
    .addSelect("COALESCE(SUM(total) FILTER (WHERE status = 'delivered'), 0)", 'revenue')
    .getRawOne();

  return {
    total: parseInt(stats.total),
    pending: parseInt(stats.pending),
    completed: parseInt(stats.completed),
    revenue: parseFloat(stats.revenue),
  };
}
```

`getRawOne()` returns strings for every numeric aggregate. Parse at the boundary, as
above, or the JSON response ships `"total": "17"` to clients.

## Error Handling

### Service-Level Exceptions

```typescript
// Use NestJS built-in exceptions
import {
  NotFoundException,
  BadRequestException,
  ForbiddenException,
  ConflictException,
} from '@nestjs/common';

async updateOrder(uuid: string, customerId: number, dto: UpdateOrderDto) {
  const order = await this.findByUuid(uuid);

  // Authorization check
  if (order.customerId !== customerId) {
    throw new ForbiddenException('Not authorized to modify this order');
  }

  // Business rule check
  if (order.status === 'delivered') {
    throw new BadRequestException('Cannot modify delivered orders');
  }

  // Conflict check
  if (dto.status && order.status === dto.status) {
    throw new ConflictException('Order already has this status');
  }

  // ... update logic
}
```

| Condition | Exception | Status |
|---|---|---|
| Record does not exist | `NotFoundException` | 404 |
| Caller may not touch this record | `ForbiddenException` | 403 |
| Missing or invalid credentials | `UnauthorizedException` | 401 |
| Business rule violated | `BadRequestException` | 400 |
| State already satisfies the request | `ConflictException` | 409 |

### Global Exception Filter (Optional)

```typescript
// filters/http-exception.filter.ts
import {
  ExceptionFilter,
  Catch,
  ArgumentsHost,
  HttpException,
  HttpStatus,
} from '@nestjs/common';

@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse();
    const request = ctx.getRequest();

    const status =
      exception instanceof HttpException
        ? exception.getStatus()
        : HttpStatus.INTERNAL_SERVER_ERROR;

    const message =
      exception instanceof HttpException
        ? exception.message
        : 'Internal server error';

    response.status(status).json({
      statusCode: status,
      message,
      timestamp: new Date().toISOString(),
      path: request.url,
    });
  }
}
```

## Exception Filters and Error Shape

```ts
@Catch()
export class HttpExceptionFilter implements ExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost) {
    const response = host.switchToHttp().getResponse<Response>();
    const request = host.switchToHttp().getRequest<Request>();

    if (exception instanceof HttpException) {
      return response.status(exception.getStatus()).json({
        path: request.url,
        error: exception.getResponse(),
      });
    }

    return response.status(500).json({
      path: request.url,
      error: 'Internal server error',
    });
  }
}
```

- Keep one consistent error envelope across the API.
- Throw framework exceptions for expected client errors; log and wrap unexpected failures centrally.

## Configuration

### Environment-Based Config

```typescript
// config/database.config.ts
import { registerAs } from '@nestjs/config';

export default registerAs('database', () => ({
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '5432', 10),
  username: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  synchronize: process.env.NODE_ENV !== 'production',
  logging: process.env.NODE_ENV === 'development',
}));
```

### Using Config in Services

```typescript
import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class MyService {
  private readonly apiUrl: string;

  constructor(private readonly configService: ConfigService) {
    this.apiUrl = this.configService.getOrThrow('EXTERNAL_API_URL');
  }
}
```

`getOrThrow` in the constructor fails the boot, not the first request. Prefer it over
`get` for anything the service cannot run without.

## Config and Environment Validation

```ts
ConfigModule.forRoot({
  isGlobal: true,
  load: [configuration],
  validate: validateEnv,
});
```

- Validate env at boot, not lazily at first request.
- Keep config access behind typed helpers or config services.
- Split dev/staging/prod concerns in config factories instead of branching throughout feature code.

## Persistence and Transactions

- Keep repository / ORM code behind providers that speak domain language.
- For Prisma or TypeORM, isolate transactional workflows in services that own the unit of work.
- Do not let controllers coordinate multi-step writes directly.

## Testing Patterns

### Unit Test Pattern

```typescript
// orders.service.spec.ts
import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { OrdersService } from './orders.service';
import { Order } from '../../entities/order.entity';

describe('OrdersService', () => {
  let service: OrdersService;
  let mockRepository: any;

  beforeEach(async () => {
    mockRepository = {
      findOne: jest.fn(),
      find: jest.fn(),
      create: jest.fn(),
      save: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        OrdersService,
        {
          provide: getRepositoryToken(Order),
          useValue: mockRepository,
        },
      ],
    }).compile();

    service = module.get<OrdersService>(OrdersService);
  });

  describe('findByUuid', () => {
    it('should return order when found', async () => {
      const mockOrder = { uuid: 'test-uuid', status: 'pending' };
      mockRepository.findOne.mockResolvedValue(mockOrder);

      const result = await service.findByUuid('test-uuid');

      expect(result).toEqual(mockOrder);
      expect(mockRepository.findOne).toHaveBeenCalledWith({
        where: { uuid: 'test-uuid' },
        relations: expect.any(Array),
      });
    });

    it('should throw NotFoundException when not found', async () => {
      mockRepository.findOne.mockResolvedValue(null);

      await expect(service.findByUuid('not-found')).rejects.toThrow(
        'Order not found',
      );
    });
  });
});
```

### HTTP-Level Test Pattern

```ts
describe('UsersController', () => {
  let app: INestApplication;

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      imports: [UsersModule],
    }).compile();

    app = moduleRef.createNestApplication();
    app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true }));
    await app.init();
  });
});
```

- Unit test providers in isolation with mocked dependencies.
- Add request-level tests for guards, validation pipes, and exception filters.
- Reuse the same global pipes/filters in tests that you use in production.

## Production Defaults

- Enable structured logging and request correlation ids.
- Terminate on invalid env/config instead of booting partially.
- Prefer async provider initialization for DB/cache clients with explicit health checks.
- Keep background jobs and event consumers in their own modules, not inside HTTP controllers.
- Make rate limiting, auth, and audit logging explicit for public endpoints.

## Review Checklist

Before a NestJS change is done:

- [ ] Every new request DTO is validated and reaches the global `ValidationPipe`
- [ ] Controllers contain no business logic and no direct repository calls
- [ ] Guards are stacked in dependency order (auth before role)
- [ ] Multi-table writes run inside a transaction with `release()` in `finally`
- [ ] Optional query-string params carry `@Type(() => Number)` where numeric
- [ ] Raw aggregate results are parsed before leaving the service
- [ ] Config the service cannot start without uses `getOrThrow` at construction time
- [ ] `synchronize` is off for anything but local development
- [ ] No entity is returned straight to the client with internal fields attached
- [ ] Tests exist for the guard, the validation failure, and the not-found path

## Related Skills

- [typeorm-patterns](../typeorm-patterns/SKILL.md) — entity definition, nullable columns,
  service-layer `null`/`undefined` rules, and the TypeORM error index
- [database-migrations](../database-migrations/SKILL.md) — schema changes, rollbacks, and
  the production alternative to `synchronize: true`

## In this pipeline

- Work is a work order: open it with `wo new`, size it honestly, fill the SPEC before code.
- Verification means behavioural tests that **ran**: `wo verify <n> --run <suite>` writes the status from the exit code. `NOT EXECUTED — PLAN ONLY` is honest; a typed `PASS` is not.
- Search the playbooks before building: `playbook search "<problem>"`.
- Route by area: `wo new --area`, `bug new --category`; the routing tables are in `core/rules/common/`.
