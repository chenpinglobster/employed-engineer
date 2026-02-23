# GUI (React) Project Verification Strategy

**Project Type:** React/Next.js/Remix Frontend Application

## Detection Criteria

Matched when:
- `package.json` dependencies include `react`
- OR: Has `src/components/` or `src/app/` directory
- OR: Has `next.config.js` or `remix.config.js`

## Verification Approach

**Focus:** DOM state, component rendering, user interactions

### Artifacts Required

| File | Content |
|------|---------|
| `dom_assertions.json` | Selector-based UI checks |
| `dom_snapshot.html` | Key DOM fragments (not full page) |
| `test_summary.txt` | Component test results |
| `screenshot_*.png` | Visual verification (when DOM insufficient) |

### Verification Steps

1. **Build**
   ```bash
   ./acceptance/run_allowed.sh build
   # Verify: dist/ or .next/ contains built assets
   ```

2. **Component Tests**
   ```bash
   ./acceptance/run_allowed.sh test
   # Verify: React Testing Library tests pass
   ```

3. **DOM Assertions (Preferred)**
   Use React Testing Library or Playwright for DOM-based checks:
   
   ```javascript
   // Check button exists and is clickable
   const button = screen.getByRole('button', { name: /add task/i });
   expect(button).toBeEnabled();
   
   // Check input has correct value
   const input = screen.getByLabelText(/task name/i);
   expect(input).toHaveValue('Buy milk');
   
   // Check list item rendered
   const item = screen.getByText(/buy milk/i);
   expect(item).toBeInTheDocument();
   ```

4. **Visual Verification (Fallback)**
   Only when DOM is insufficient (Canvas, WebGL, complex CSS):
   
   ```bash
   npx playwright test --screenshot=on-failure
   # Compare screenshot hashes or use visual regression
   ```

## Assertion Types

### 1. DOM Element Exists
```json
{
  "type": "element_exists",
  "selector": "button[aria-label='Add Task']",
  "expected": true
}
```

### 2. Text Content
```json
{
  "type": "text_content",
  "selector": ".todo-item:first-child",
  "expected": "Buy milk",
  "match": "exact"
}
```

### 3. Element State
```json
{
  "type": "element_state",
  "selector": "button[type='submit']",
  "property": "disabled",
  "expected": false
}
```

### 4. CSS Property
```json
{
  "type": "css_property",
  "selector": ".completed-task",
  "property": "text-decoration",
  "expected": "line-through"
}
```

### 5. Accessible Name (ARIA)
```json
{
  "type": "accessible_name",
  "role": "button",
  "name": "Delete task",
  "expected": true
}
```

### 6. Screenshot Hash (Fallback)
```json
{
  "type": "screenshot_hash",
  "file": "screenshot_home.png",
  "hash": "a3f2b9c8d1e5",
  "tolerance": 0.01
}
```

## Acceptance Criteria

✅ **PASS when:**
- Component tests pass
- DOM assertions match expected state
- No console errors in test output
- Accessibility checks pass (if configured)

❌ **FAIL when:**
- Component tests fail
- DOM elements missing or wrong content
- Console errors/warnings
- Screenshot hashes differ (if used)

## Example React DOM Assertions

```json
{
  "version": "1.0",
  "page": "Todo List",
  "assertions": [
    {
      "type": "element_exists",
      "selector": "input[placeholder='Add a new task']",
      "pass": true
    },
    {
      "type": "text_content",
      "selector": "h1",
      "expected": "My Todo List",
      "actual": "My Todo List",
      "pass": true
    },
    {
      "type": "element_state",
      "selector": "button[type='submit']",
      "property": "disabled",
      "expected": true,
      "actual": true,
      "pass": true
    },
    {
      "type": "accessible_name",
      "role": "button",
      "name": "Add Task",
      "found": true,
      "pass": true
    }
  ]
}
```

## Template Structure

For React projects, bootstrap with:

```
acceptance/
├── run_allowed.sh
├── smoke.sh
├── e2e.sh               # Playwright/Cypress E2E
└── artifacts/
    └── latest/
        ├── report.json
        ├── dom_assertions.json
        ├── dom_snapshot.html
        ├── test_summary.txt
        └── screenshots/        # Only when DOM insufficient
            └── failure_*.png
```

## DOM-First Philosophy

**Always prefer DOM assertions over screenshots:**

| Scenario | Use DOM | Use Screenshot |
|----------|---------|----------------|
| Button exists | ✅ `getByRole('button')` | ❌ |
| Text displayed | ✅ `getByText()` | ❌ |
| Input value | ✅ `input.value` | ❌ |
| Element visible | ✅ `isVisible()` | ❌ |
| Canvas chart | ❌ | ✅ (no DOM data) |
| CSS animation | ✅ `computedStyle` | ⚠️ (if subtle) |
| Exact layout | ⚠️ (brittle) | ✅ (last resort) |

## Common Issues

| Issue | Detection | Fix |
|-------|-----------|-----|
| Element not found | DOM assertion fails | Check selector or timing |
| Wrong text | Expected X, got Y | Update component logic |
| Disabled button | Should be enabled | Check form validation |
| Console errors | React warnings in log | Fix warnings/errors |

## React Testing Library Best Practices

```javascript
// ✅ Good - queries by user-visible text
screen.getByRole('button', { name: /add/i })
screen.getByLabelText(/task name/i)
screen.getByText(/buy milk/i)

// ❌ Bad - queries by implementation details
screen.getByTestId('add-button')
container.querySelector('.btn-primary')
```

---

**Token efficiency:** Use DOM assertions JSON. Only screenshot when absolutely necessary. Never read component source unless DOM analysis fails.
