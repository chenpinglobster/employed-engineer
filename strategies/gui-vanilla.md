# GUI (Vanilla) Project Verification Strategy

**Project Type:** Plain HTML/CSS/JavaScript Frontend

## Detection Criteria

Matched when:
- Has `.html` files in `src/` or `public/` directory
- AND: NO `react`, `vue`, `angular`, `svelte` in dependencies
- OR: `index.html` directly in project root

## Verification Approach

**Focus:** DOM state, vanilla JS behavior, no framework assumptions

### Artifacts Required

| File | Content |
|------|---------|
| `dom_assertions.json` | Selector-based UI checks |
| `dom_snapshot.html` | Key DOM fragments |
| `test_summary.txt` | Test results (if using Vitest/Jest) |
| `screenshot_*.png` | Visual verification (fallback) |

### Verification Steps

1. **Serve**
   ```bash
   # Start simple HTTP server
   python3 -m http.server 8000 &
   sleep 1
   ```

2. **DOM Tests**
   Use Playwright or Puppeteer for DOM checks:
   
   ```javascript
   // Open page
   await page.goto('http://localhost:8000');
   
   // Check button exists
   const button = await page.$('button#add-task');
   expect(button).toBeTruthy();
   
   // Check text content
   const title = await page.textContent('h1');
   expect(title).toBe('Todo List');
   
   // Interact and verify
   await page.fill('input#task-input', 'Buy milk');
   await page.click('button#add-task');
   const item = await page.textContent('.todo-item:first-child');
   expect(item).toContain('Buy milk');
   ```

3. **Visual Check (if needed)**
   ```bash
   npx playwright screenshot --full-page http://localhost:8000
   ```

## Assertion Types

### 1. DOM Element Exists
```json
{
  "type": "element_exists",
  "selector": "button#add-task",
  "expected": true
}
```

### 2. Text Content
```json
{
  "type": "text_content",
  "selector": "h1.title",
  "expected": "Todo List",
  "match": "exact"
}
```

### 3. Element Attribute
```json
{
  "type": "element_attribute",
  "selector": "input#task-input",
  "attribute": "placeholder",
  "expected": "Enter a task..."
}
```

### 4. Element Count
```json
{
  "type": "element_count",
  "selector": ".todo-item",
  "expected": 3
}
```

### 5. CSS Class Presence
```json
{
  "type": "has_class",
  "selector": ".todo-item:first-child",
  "class": "completed",
  "expected": false
}
```

### 6. JavaScript Interaction
```json
{
  "type": "interaction_result",
  "action": "click('#add-task')",
  "verify": {
    "selector": ".todo-item",
    "count": 1
  }
}
```

## Acceptance Criteria

✅ **PASS when:**
- All DOM elements present
- Event handlers work correctly
- State updates reflected in DOM
- No console errors

❌ **FAIL when:**
- Missing DOM elements
- JavaScript errors in console
- Event handlers don't fire
- State not updating

## Example Vanilla JS Assertions

```json
{
  "version": "1.0",
  "page": "Todo App",
  "url": "http://localhost:8000/index.html",
  "assertions": [
    {
      "type": "element_exists",
      "selector": "input#task-input",
      "pass": true
    },
    {
      "type": "text_content",
      "selector": "h1",
      "expected": "My Tasks",
      "actual": "My Tasks",
      "pass": true
    },
    {
      "type": "element_count",
      "selector": ".todo-item",
      "expected": 0,
      "actual": 0,
      "pass": true
    },
    {
      "type": "interaction_result",
      "action": "fill('#task-input', 'Buy milk') → click('#add-task')",
      "verify": {
        "selector": ".todo-item",
        "expected_count": 1,
        "actual_count": 1
      },
      "pass": true
    }
  ]
}
```

## Template Structure

For vanilla JS projects, bootstrap with:

```
acceptance/
├── run_allowed.sh
├── smoke.sh
├── dom_test.js          # Playwright/Puppeteer tests
└── artifacts/
    └── latest/
        ├── report.json
        ├── dom_assertions.json
        ├── dom_snapshot.html
        └── screenshots/
            └── page.png
```

## Testing Vanilla JS

### Using Playwright

```javascript
import { chromium } from 'playwright';

const browser = await chromium.launch();
const page = await browser.newPage();

await page.goto('http://localhost:8000');

// Test 1: Page loads
const title = await page.textContent('h1');
console.assert(title === 'Todo List');

// Test 2: Add task works
await page.fill('#task-input', 'Buy milk');
await page.click('#add-task');

const itemCount = await page.locator('.todo-item').count();
console.assert(itemCount === 1);

// Test 3: Task content correct
const itemText = await page.textContent('.todo-item');
console.assert(itemText.includes('Buy milk'));

await browser.close();
```

## Common Issues

| Issue | Detection | Fix |
|-------|-----------|-----|
| Element not found | DOM assertion fails | Check HTML structure |
| Event not firing | Interaction fails | Check event listeners |
| Wrong content | Text mismatch | Update JS logic |
| Console errors | Errors in log | Fix JS bugs |

## DOM-First, Screenshot-Last

| Scenario | Use DOM | Use Screenshot |
|----------|---------|----------------|
| Button text | ✅ `textContent` | ❌ |
| Input value | ✅ `input.value` | ❌ |
| Element visible | ✅ `isVisible()` | ❌ |
| Exact spacing | ⚠️ (brittle) | ✅ (last resort) |

---

**Token efficiency:** Use DOM assertions JSON. Screenshot only for visual-heavy apps (games, editors). Never read JS source unless DOM analysis fails.
