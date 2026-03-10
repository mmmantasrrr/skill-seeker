# Examples and Use Cases

This document provides real-world examples of how to use Skill-Seeker to solve common development challenges. Each example includes the problem, the command used, and the outcome.

## Table of Contents

- [Frontend Development](#frontend-development)
- [Backend Development](#backend-development)
- [Testing and QA](#testing-and-qa)
- [DevOps and Infrastructure](#devops-and-infrastructure)
- [Security and Code Review](#security-and-code-review)
- [API Development](#api-development)
- [Database Design](#database-design)
- [Performance Optimization](#performance-optimization)

## Frontend Development

### Example 1: Redesigning a Landing Page with Design Audit

**Problem**: You need to redesign a landing page but want to ensure it follows modern design principles.

**Solution**:
```bash
# Search for design-related skills
/skill-seeker:seek frontend design

# Install the Impeccable design audit framework
/skill-seeker:install pbakaus/impeccable/.claude/skills/impeccable/SKILL.md
```

**Outcome**: Claude now applies strict design taste principles, checking for:
- Visual hierarchy and spacing
- Typography consistency
- Color contrast and accessibility
- Responsive design patterns
- Modern UI conventions

**Before vs After**:
- Before: Generic suggestions like "make it look better"
- After: Specific feedback like "Increase heading size by 1.5x for better hierarchy" or "Add 40px spacing between sections for breathing room"

### Example 2: React Component Best Practices

**Problem**: Writing React components without clear patterns or consistency.

**Solution**:
```bash
/skill-seeker:seek react patterns
/skill-seeker:install [selected-repo]/.claude/skills/react-best-practices/SKILL.md
```

**What You Get**:
- Proper hook usage patterns
- Component composition guidelines
- State management best practices
- Performance optimization techniques
- Accessibility considerations

### Example 3: CSS Architecture

**Problem**: CSS is getting messy and hard to maintain.

**Solution**:
```bash
/skill-seeker:seek css architecture
```

**Skills You Might Find**:
- BEM naming conventions
- CSS-in-JS patterns
- Tailwind CSS best practices
- CSS Grid and Flexbox layouts
- Responsive design patterns

## Backend Development

### Example 4: RESTful API Design

**Problem**: Building a REST API but unsure about endpoint structure and conventions.

**Solution**:
```bash
/skill-seeker:seek rest api design
/skill-seeker:install [repo]/skills/rest-api-patterns/SKILL.md
```

**What Claude Will Apply**:
- Resource naming conventions (plural nouns)
- HTTP method usage (GET, POST, PUT, DELETE)
- Status code selection (200, 201, 404, 500, etc.)
- Error response formats
- Pagination and filtering patterns
- API versioning strategies

**Example Output**:
Instead of: `POST /user/create`
Claude suggests: `POST /api/v1/users`

### Example 5: Node.js Error Handling

**Problem**: Inconsistent error handling across your Node.js application.

**Solution**:
```bash
/skill-seeker:seek nodejs error handling
```

**Benefits**:
- Centralized error handling middleware
- Proper error logging
- User-friendly error messages
- Stack trace management
- Async/await error patterns

### Example 6: Database Schema Design

**Problem**: Designing a database schema for a multi-tenant application.

**Solution**:
```bash
/skill-seeker:seek database design patterns
```

**What You Learn**:
- Normalization vs denormalization
- Index strategy
- Foreign key relationships
- Query optimization
- Migration best practices

## Testing and QA

### Example 7: Playwright E2E Testing

**Problem**: Need to write reliable browser automation tests.

**Solution**:
```bash
/skill-seeker:seek playwright testing
/skill-seeker:install [repo]/skills/playwright-best-practices/SKILL.md
```

**What Changes**:
- Proper use of test fixtures
- Page Object Model pattern
- Reliable selectors (data-testid)
- Waiting strategies (no arbitrary sleep)
- Parallelization techniques
- Screenshot and video debugging

**Before**:
```javascript
await page.click('#submit-button');
await page.waitForTimeout(2000); // Bad: arbitrary wait
```

**After**:
```javascript
await page.getByTestId('submit-button').click();
await page.waitForURL('**/success'); // Good: wait for navigation
```

### Example 8: Unit Testing Strategy

**Problem**: Writing effective unit tests with good coverage.

**Solution**:
```bash
/skill-seeker:seek unit testing best practices
```

**Coverage Areas**:
- Test organization (describe/it blocks)
- Mocking and stubbing
- Test isolation
- Assertion patterns
- Code coverage goals

## DevOps and Infrastructure

### Example 9: Terraform Infrastructure as Code

**Problem**: Writing maintainable Terraform configurations.

**Solution**:
```bash
/skill-seeker:seek terraform patterns
/skill-seeker:install [repo]/skills/terraform-iac/SKILL.md
```

**Best Practices Applied**:
- Module organization
- Variable and output naming
- State management
- Remote backend configuration
- Resource tagging standards
- Security group rules

**Example Improvement**:
Instead of inline resources, Claude suggests modular structure:
```
modules/
  vpc/
  compute/
  database/
environments/
  dev/
  staging/
  production/
```

### Example 10: Docker Container Optimization

**Problem**: Docker images are too large and build slowly.

**Solution**:
```bash
/skill-seeker:seek docker optimization
```

**Optimizations Suggested**:
- Multi-stage builds
- Layer caching strategies
- Alpine-based images
- .dockerignore usage
- Build argument patterns
- Health check configurations

**Result**: Image size reduced from 800MB to 150MB, build time from 5min to 1min.

### Example 11: CI/CD Pipeline Setup

**Problem**: Setting up a robust CI/CD pipeline with GitHub Actions.

**Solution**:
```bash
/skill-seeker:seek ci cd github actions
```

**Pipeline Improvements**:
- Proper job dependencies
- Caching strategies
- Matrix builds
- Secret management
- Deployment strategies
- Rollback procedures

## Security and Code Review

### Example 12: Security Code Review

**Problem**: Need to audit code for common security vulnerabilities.

**Solution**:
```bash
/skill-seeker:seek security owasp
/skill-seeker:install [repo]/skills/owasp-checklist/SKILL.md
```

**Security Checks**:
- SQL injection vulnerabilities
- XSS (Cross-Site Scripting) prevention
- CSRF token validation
- Authentication and authorization
- Sensitive data exposure
- Security misconfiguration
- Insecure dependencies

**Example Detection**:
```javascript
// Before: SQL Injection vulnerability
const query = `SELECT * FROM users WHERE id = ${userId}`;

// After: Parameterized query
const query = 'SELECT * FROM users WHERE id = ?';
db.query(query, [userId]);
```

### Example 13: Code Quality Review

**Problem**: Ensuring consistent code quality across the team.

**Solution**:
```bash
/skill-seeker:seek code review checklist
```

**Review Areas**:
- Code style consistency
- Function complexity
- Variable naming
- Comment quality
- Test coverage
- Performance considerations

## API Development

### Example 14: GraphQL API Design

**Problem**: Designing a GraphQL schema that's intuitive and performant.

**Solution**:
```bash
/skill-seeker:seek graphql schema design
```

**Schema Patterns**:
- Type naming conventions
- Query vs Mutation organization
- Pagination (cursor-based)
- Error handling
- N+1 query prevention
- DataLoader usage

### Example 15: API Documentation

**Problem**: Creating comprehensive API documentation.

**Solution**:
```bash
/skill-seeker:seek api documentation swagger
```

**Documentation Standards**:
- OpenAPI/Swagger spec
- Request/response examples
- Authentication documentation
- Error code reference
- Rate limiting details
- Versioning information

## Database Design

### Example 16: PostgreSQL Optimization

**Problem**: Slow database queries affecting application performance.

**Solution**:
```bash
/skill-seeker:seek postgresql optimization
```

**Optimization Techniques**:
- Index strategy (B-tree, GiST, GIN)
- Query plan analysis (EXPLAIN)
- Connection pooling
- Vacuum and analyze
- Partitioning large tables
- Materialized views

**Performance Impact**:
- Before: Query takes 3.2 seconds
- After: Query takes 45ms with proper indexing

### Example 17: MongoDB Schema Design

**Problem**: Designing efficient MongoDB schemas for a social media app.

**Solution**:
```bash
/skill-seeker:seek mongodb schema patterns
```

**Design Patterns**:
- Embedding vs referencing
- Document structure
- Array handling
- Aggregation pipeline
- Sharding strategy
- Index optimization

## Performance Optimization

### Example 18: React Performance Optimization

**Problem**: React app is slow with large lists and frequent re-renders.

**Solution**:
```bash
/skill-seeker:seek react performance
```

**Optimization Strategies**:
- React.memo usage
- useMemo and useCallback
- Virtual scrolling for large lists
- Code splitting
- Lazy loading components
- Bundle size optimization

**Metrics**:
- Initial load time: 3s → 1.2s
- Time to interactive: 5s → 2s
- Bundle size: 2.5MB → 800KB

### Example 19: Node.js Performance Tuning

**Problem**: Node.js API server struggling under load.

**Solution**:
```bash
/skill-seeker:seek nodejs performance
```

**Performance Improvements**:
- Clustering and worker processes
- Memory leak detection
- Event loop monitoring
- Caching strategies (Redis)
- Database connection pooling
- Rate limiting

**Results**:
- Requests per second: 500 → 3000
- Response time (p95): 800ms → 120ms
- CPU usage: 90% → 45%

## Advanced Use Cases

### Example 20: Multi-Skill Workflow

**Problem**: Building a production-ready feature requires multiple expertise areas.

**Solution**: Load multiple complementary skills
```bash
# Load security scanning
/skill-seeker:seek security owasp
/skill-seeker:install [repo]/skills/security/SKILL.md

# Load API design patterns
/skill-seeker:seek rest api design
/skill-seeker:install [repo]/skills/api-design/SKILL.md

# Load testing best practices
/skill-seeker:seek testing patterns
/skill-seeker:install [repo]/skills/testing/SKILL.md
```

**Outcome**: Claude applies all three frameworks simultaneously:
1. Checks for security vulnerabilities
2. Follows API design conventions
3. Writes comprehensive tests

### Example 21: Legacy Code Refactoring

**Problem**: Refactoring a legacy codebase to modern standards.

**Solution**:
```bash
/skill-seeker:seek refactoring patterns
/skill-seeker:seek clean code principles
```

**Refactoring Applied**:
- Extract method/class
- Remove code duplication
- Simplify conditionals
- Rename for clarity
- Add type annotations
- Improve error handling

### Example 22: Debugging Complex Issues

**Problem**: Tracking down a production bug.

**Solution**:
```bash
/skill-seeker:seek debugging strategies
```

**Debugging Approach**:
- Systematic issue reproduction
- Log analysis patterns
- Binary search debugging
- Hypothesis-driven investigation
- Performance profiling
- Memory leak detection

## Tips for Maximum Benefit

### 1. Be Specific in Your Searches

❌ Bad: `/skill-seeker:seek frontend`
✅ Good: `/skill-seeker:seek react hooks patterns`

### 2. Combine Multiple Skills

For complex tasks, load 2-3 complementary skills:
- Security + API design
- Testing + Performance
- Design + Accessibility

### 3. Unload When Switching Contexts

```bash
/skill-seeker:unload
```

This prevents skill conflicts when switching from frontend to backend work.

### 4. Check Trust Scores

High trust scores (60+) indicate well-maintained, community-validated skills.

### 5. Preview Before Installing

Review the security scan results before loading any skill.

## Measuring Success

### Before Using Skill-Seeker
- Generic code suggestions
- Inconsistent patterns
- Missing best practices
- Manual research for each decision

### After Using Skill-Seeker
- Specific, actionable guidance
- Consistent patterns across codebase
- Automated best practice application
- Faster development with fewer mistakes

## Community Contributions

Have a great use case? Share it!

1. Open an issue with your example
2. Submit a PR to this file
3. Create a skill and add it to the registry

---

**Need Help?** Check the main [README](README.md) or open an [issue](https://github.com/mmmantasrrr/skill-seeker/issues).
