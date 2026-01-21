---
description: "Generate a codebase Pin (searchable index) for Ralf context"
argument-hint: "[output path]"
---

# Generate Pin Command

Creates a searchable codebase index ("Pin") that provides context for Ralf story execution.

## What is a Pin?

A Pin is a condensed, searchable summary of your codebase that helps Ralf:
- Understand project structure without loading entire codebase
- Find relevant files for each story
- Identify existing patterns to follow
- Avoid duplicating existing functionality

## The Job

1. Scan the codebase structure
2. Extract key information from each file type
3. Generate a searchable index at `specs/readme.md`
4. Include patterns, APIs, components, and conventions

## Scan Strategy

### Directory Structure
```
- Map all directories and their purposes
- Identify key folders: src/, lib/, components/, pages/, api/, etc.
- Note test directories and configuration files
```

### File Analysis

**For TypeScript/JavaScript:**
- Extract exports (functions, classes, types, interfaces)
- Identify API endpoints
- Map component hierarchy
- Note state management patterns

**For Python:**
- Extract classes and functions
- Identify entry points
- Map module structure

**For Config Files:**
- Package.json dependencies
- Build configuration
- Environment variables (names only, not values)

## Output Format

Generate `specs/readme.md` with this structure:

```markdown
# [Project Name] - Codebase Pin

Generated: [timestamp]
Files scanned: [count]
Total lines: [count]

## Project Overview

[Brief description from package.json, README, or inference]

## Directory Structure

```
src/
├── components/     # React components
├── pages/          # Next.js pages
├── lib/            # Utility functions
├── api/            # API routes
└── types/          # TypeScript types
```

## Key Patterns

### State Management
- [Pattern description]
- Key files: [list]

### API Layer
- [Pattern description]
- Endpoints defined in: [list]

### Component Architecture
- [Pattern description]
- Base components: [list]

## Public API

### Exports from src/index.ts
- `functionName(args)` - Description
- `ClassName` - Description
- `TypeName` - Description

### API Endpoints
- `GET /api/users` - List users
- `POST /api/auth/login` - Authenticate

## Types & Interfaces

### Core Types
```typescript
interface User { ... }
type AuthState = { ... }
```

## Dependencies

### Production
- react: ^18.0.0
- next: ^14.0.0

### Development
- typescript: ^5.0.0
- jest: ^29.0.0

## Conventions

### Naming
- Components: PascalCase
- Functions: camelCase
- Files: kebab-case

### File Organization
- One component per file
- Tests co-located with source

## Environment Variables

Required (names only):
- DATABASE_URL
- API_KEY
- NEXT_PUBLIC_*

## Build & Run

```bash
npm run dev      # Development
npm run build    # Production build
npm test         # Run tests
```

## Notes for Implementation

- [Key gotchas discovered]
- [Patterns to follow]
- [Areas to avoid modifying]
```

## Scan Commands

Use these to gather information:

```bash
# Directory structure
find . -type d -not -path '*/node_modules/*' -not -path '*/.git/*' | head -50

# TypeScript exports
grep -r "^export" --include="*.ts" --include="*.tsx" src/

# Package dependencies
cat package.json | jq '.dependencies, .devDependencies'

# API routes (Next.js)
find . -path '*/api/*' -name '*.ts' | head -20

# React components
find . -name '*.tsx' -path '*/components/*' | head -30
```

## Output Location

Save to: `specs/readme.md` (default) or custom path from arguments

## When to Regenerate

- After major refactoring
- When adding new modules
- Before starting a new PRD
- When Ralf struggles to find patterns

## Integration with Ralf

The Pin is automatically loaded by story-executor when:
1. `specs/readme.md` exists
2. Story requires understanding project structure
3. RLM processor needs codebase overview

## Checklist

- [ ] Scanned all source directories
- [ ] Extracted public API
- [ ] Documented patterns
- [ ] Listed dependencies
- [ ] Noted environment variables (names only!)
- [ ] Included build commands
- [ ] Saved to specs/readme.md
