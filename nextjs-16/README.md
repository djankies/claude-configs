# Next.js 16 Plugin for Claude Code

A comprehensive Claude Code plugin that provides intelligent guidance for Next.js 16's breaking changes, the Cache Components paradigm shift, and critical security patterns including CVE-2025-29927 mitigation.

## Overview

Next.js 16 introduces fundamental changes that affect every application:

- **Critical Security Vulnerability (CVE-2025-29927)**: Middleware authentication bypass requiring new security patterns
- **Cache Components Paradigm**: Shift from "cached by default" to "dynamic by default" with explicit `'use cache'` directive
- **Breaking Changes**: Async request APIs (`cookies()`, `headers()`, `params`, `searchParams`) now require `await`
- **Missing Authentication**: Server actions without proper security verification

This plugin provides **context-aware skills** that activate intelligently based on your work, preventing security vulnerabilities and migration errors before they happen.

## Installation

```bash
claude plugins add nextjs-16
```

Or via marketplace URL:

```bash
claude plugins add https://github.com/anthropic/claude-plugins/nextjs-16
```

## Features

### 9 Intelligent Skills (Organized by Concern)

#### SECURITY

1. **security-data-access-layer** - Implements the Data Access Layer (DAL) pattern to prevent CVE-2025-29927 middleware authentication bypass. Teaches multi-layer security with `verifySession()` at every access point.

#### CACHING

2. **caching-use-cache-directive** - Teaches the Cache Components model with `'use cache'` directive. Covers file-level, component-level, and function-level caching with dynamic invalidation.

3. **caching-lifecycle-apis** - Implements caching lifecycle APIs (`cacheLife()`, `cacheTag()`, `revalidateTag()`, `revalidatePath()`). Teaches cache profiles, tagging strategies, and selective invalidation.

#### MIGRATION

4. **migration-async-request-apis** - Migrates synchronous request APIs to async. Handles `cookies()`, `headers()`, `params`, and `searchParams` with proper `await` patterns.

5. **migration-middleware-to-proxy** - Migrates middleware-based authentication to Data Access Layer (DAL) + proxy pattern. Addresses CVE-2025-29927 in existing codebases.

#### ROUTING

6. **routing-parallel-routes** - Implements parallel routes with proper slot handling, default fallbacks, and conditional rendering patterns.

#### FORMS

7. **forms-server-actions-security** - Secures server actions with authentication, authorization, input validation, and error handling. Prevents unauthorized access.

#### IMAGES

8. **images-optimization-config** - Implements Next.js 16 Image optimization with proper sizing, lazy loading, priority loading, and responsive images.

#### REVIEW

9. **review-nextjs-16-patterns** - Reviews codebases for Next.js 16 compliance. Identifies security issues, caching problems, migration needs, and anti-patterns.

## Intelligent Activation

This plugin uses **hook-based skill recommendations** to provide context-aware guidance:

### Session Start Hook

When you start a Claude Code session, the plugin:
- Detects Next.js 16 projects
- Shows available skills
- Provides quick-start guidance

### Pre-Tool-Use Hook

Before you write or edit files, the plugin:
- Analyzes file paths and contexts
- Recommends relevant skills automatically
- Prevents common mistakes before they happen

Example recommendations:

- Editing `middleware.ts` → Recommends **security-data-access-layer** and **migration-middleware-to-proxy**
- Creating `app/*/page.tsx` → Recommends **caching-use-cache-directive** and **security-data-access-layer**
- Editing server actions → Recommends **forms-server-actions-security**
- Editing `lib/auth.ts` or `lib/session.ts` → Recommends **security-data-access-layer**

## Components

### Skills (9 total)

Skills are **autonomous capabilities** that teach patterns and best practices:

```tree
skills/
├── SECURITY-data-access-layer/
├── CACHING-use-cache-directive/
├── CACHING-lifecycle-apis/
├── MIGRATION-async-request-apis/
├── MIGRATION-middleware-to-proxy/
├── ROUTING-parallel-routes/
├── FORMS-server-actions-security/
├── IMAGES-optimization-config/
└── REVIEW-nextjs-16-patterns/
```

Each skill:
- Activates based on context
- Provides executable code patterns
- Prevents common mistakes
- Teaches best practices

### Hooks (2 total)

Hooks provide **lifecycle integration** for intelligent behavior:

1. **SessionStart** - Runs `init-session.sh` at session start to detect Next.js 16 projects
2. **PreToolUse** - Runs `recommend-skills.sh` before file operations to suggest relevant skills

### MCP Server

The plugin includes the **next-devtools** MCP server for enhanced tooling:

```json
{
  "mcpServers": {
    "next-devtools": {
      "command": "npx",
      "args": ["-y", "next-devtools-mcp@latest"]
    }
  }
}
```

Provides tools for:
- Project structure analysis
- Dependency inspection
- Configuration validation
- Build optimization

### Knowledge Base

The plugin includes curated documentation:

- Next.js 16 breaking changes
- CVE-2025-29927 security advisory
- Cache Components model
- Migration guides

## Usage Examples

### Example 1: Preventing Authentication Bypass

You're editing `middleware.ts`:

```typescript
export function middleware(request: NextRequest) {
  const session = request.cookies.get('session');
  if (!session) {
    return NextResponse.redirect(new URL('/login', request.url));
  }
}
```

**Plugin activates:** security-data-access-layer

**What it teaches:**
- Middleware-only authentication is broken (CVE-2025-29927)
- Implement Data Access Layer with `verifySession()`
- Add security checks to server actions, API routes, and components
- Use multi-layer security strategy

**Result:** Prevents critical security vulnerability

### Example 2: Migrating to Cache Components

You're creating a new page `app/products/page.tsx`:

```typescript
export default async function ProductsPage() {
  const products = await db.query.products.findMany()
  return <ProductList products={products} />
}
```

**Plugin activates:** caching-use-cache-directive

**What it teaches:**
- Next.js 16 is dynamic by default
- Add `'use cache'` directive for caching
- Configure cache lifetime and revalidation
- Use `cacheLife()` for custom profiles

**Result:** Optimal caching without surprising behaviors

### Example 3: Fixing Breaking Changes

You're migrating from Next.js 15:

```typescript
export default function Page({ params, searchParams }) {
  const id = params.id
  const query = searchParams.q
}
```

**Plugin activates:** migration-async-request-apis

**What it teaches:**
- `params` and `searchParams` are now async
- Add `await` to request API calls
- Update function signatures to `async`
- Handle promises correctly

**Result:** Working Next.js 16 code

## Philosophy Alignment

This plugin follows Claude Code's design principles:

### 1. No Passive Knowledge

Skills provide **executable patterns**, not documentation. Every skill teaches through concrete code examples that work in Next.js 16.

### 2. Autonomous Skills

Skills activate based on **context**, not explicit invocation. The plugin detects what you're working on and recommends relevant skills automatically.

### 3. Minimal User Burden

Hooks run **automatically** at the right moments. You don't need to remember to activate skills or check documentation.

### 4. Behavior Over Configuration

The plugin uses **lifecycle hooks** to provide intelligent behavior without configuration files or settings.

### 5. Composable Capabilities

Skills are **modular and focused**. Each addresses one concern (security, caching, migration) and can be used independently or together.

## Integration

### Works With Other Plugins

This plugin is designed to work alongside other plugins in the ecosystem:

**@react-19 Plugin:**
- **nextjs-16**: Next.js-specific patterns (routing, caching, server actions)
- **react-19**: React fundamentals (hooks, server components, transitions)

Skills can reference each other across plugins:

- `security-data-access-layer` uses React 19's `cache()` for memoization
- `caching-use-cache-directive` builds on React Server Components knowledge
- `forms-server-actions-security` references React 19's `useActionState` hook

**@prisma-6 Plugin:**
- Server action security integrates with Prisma input validation
- Transaction error handling for database operations in server actions
- Type-safe queries for data access layer implementations

Install all three for comprehensive Next.js 16 + React 19 + Prisma 6 development:

```bash
claude plugins add nextjs-16
claude plugins add react-19
claude plugins add prisma-6
```

## Contributing

Contributions are welcome! To contribute:

1. **Add New Skills**: Create skills for additional Next.js 16 patterns
2. **Improve Hooks**: Enhance skill recommendation logic
3. **Expand Knowledge**: Add more documentation and examples
4. **Report Issues**: Found a problem? Open an issue

### Development

```bash
git clone https://github.com/anthropic/claude-plugins
cd claude-plugins/nextjs-16

npm install
npm test
```

### Testing

Run validation to ensure plugin structure:

```bash
npm run validate
```

Stress test the plugin:

```bash
claude cmd stress-test
```

## License

MIT License - see LICENSE file for details

---

**Need Help?**

- Review available skills: `claude skills list`
- Review this README: `cat nextjs-16/README.md`
- Check plugin status: `claude plugins list`
- Open an issue: https://github.com/anthropic/claude-plugins/issues
