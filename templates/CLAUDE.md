# Global Development Standards

## Package Manager

Use `pnpm` (monorepos, standard projects) or `bun` (speed-critical or already in use). Never `yarn`. Migrate yarn projects to pnpm.

## Framework Selection

**Hard constraints:** Never Next.js. Never Vercel. Deploy to Cloudflare, Railway, Fly.io, AWS, or generic Node hosts only.

Silently evaluate features before scaffolding, then state the choice with a one-line rationale.

**TanStack Start** — interactive/write-heavy apps (dashboards, internal tools, multi-step forms, SPAs).
Default stack: TanStack Router (file-based, type-safe) · TanStack Query via loaders + server functions · Vite · Nitro · Zod · Zustand for client state.

**Astro** — content-first sites (marketing, blogs, docs, portfolios). Zero JS by default, React/Vue islands for interactivity. Deploy static to Cloudflare Pages or SSR with Node adapter.

**TanStack Start + prerendering** — hybrid apps with content and interactive pages in one codebase. Content routes use SSR + cache headers or Nitro prerendering; interactive routes use loaders + Query.

**React Email** — emails and email templates.

When using Tailwind, always verify and install the latest version. Fetch the framework guide before scaffolding: [TanStack Start](https://tailwindcss.com/docs/installation/framework-guides/tanstack-start) · [Astro](https://tailwindcss.com/docs/installation/framework-guides/astro).

Terraform needs to be OpenTofu when possible.

## Tests

**Runner:** Vitest for unit/integration, Playwright for E2E. Never Jest.
Co-locate unit tests as `*.test.ts(x)`; E2E specs in `e2e/`. Run the suite before any PR; never commit failing tests.

Test what can break — server functions, loaders, validators, state transitions, utilities. Skip framework internals and trivial render output.

- **TanStack Start** — Vitest for server functions, loaders, Zod schemas, Zustand stores (test the store, not the component). Playwright for write paths (auth, multi-step forms, mutations).
- **Astro** — Vitest + Container API for components; test island logic and Zod content-collection schemas, not the content. Playwright for key pages and island interactivity.
- **TanStack Start + prerendering** — both of the above; also assert prerendered routes return static HTML with no client runtime.
- **React Email** — Vitest snapshots for markup; assert dynamic props (links, names, conditionals) render correctly.

## Containers

Runtime is **OrbStack**, not Docker Desktop. The `docker` / `docker compose` CLI is unchanged — use it normally.
Never suggest installing or starting Docker Desktop, Colima, or `docker-machine`. If the daemon is unreachable, the fix is `orb start`.
Docker context: `orbstack`. Kubernetes: `orb start k8s`. VMs: `orb` / `orbctl`.

## Environment Variables & Secrets

Never read, reveal or output the contents of .env/.env.local/terraform.tfvars by any means. Work only with `.env.example` and 
Never commit real secrets. Keep `.env*` and `*.tfvars` in `.gitignore` on every level.
Maintain `.env.example` with placeholder secrets or project related values.
Accommodate for both `.env` and `.env.local` use.

## Git Workflow

Never commit directly to `main`/`master`. Always branch first, pull latest `main` beforehand.
Branch naming: `feat/`, `fix/`, `chore/`, `docs/`, `tree/` + short description, always name a branch after the feature being implemented.
Never force-push to `main`. Never `--no-verify` without explicit instruction.

## Compact Instructions

When compacting: preserve the full list of modified files, errors, and pending decisions.
