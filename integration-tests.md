# Integration Tests

Manual integration tests for verifying the lazy-loading grammar system works correctly end-to-end.

## Prerequisites

- macOS 13.0+ (Ventura)
- Internet connection (for first-time grammar downloads)
- Built SwiftMarkdown app

## Test Scenarios

### 1. Fresh Install Flow

**Purpose:** Verify grammars download correctly on first use.

**Steps:**
1. Clear grammar cache: `rm -rf ~/Library/Application\ Support/SwiftMarkdown/Grammars/`
2. Build and run SwiftMarkdown
3. Open a markdown file containing:
   ```markdown
   # Test

   ```javascript
   const greeting = "Hello";
   console.log(greeting);
   ```
   ```
4. Observe the code block

**Expected:**
- Brief delay on first render (grammar downloading)
- JavaScript code is syntax highlighted after download
- Cache directory created at `~/Library/Application Support/SwiftMarkdown/Grammars/javascript/`

**Verification:**
```bash
ls -la ~/Library/Application\ Support/SwiftMarkdown/Grammars/javascript/
# Should show: javascript.dylib, queries/highlights.scm
```

---

### 2. Cache Hit Flow

**Purpose:** Verify cached grammars are used without network requests.

**Steps:**
1. Complete Test 1 (JavaScript grammar cached)
2. Disconnect from internet
3. Open a markdown file with JavaScript code block
4. Observe rendering

**Expected:**
- Immediate syntax highlighting
- No network errors
- Code renders correctly

---

### 3. Swift Always Available

**Purpose:** Verify bundled Swift highlighting works without internet.

**Steps:**
1. Clear grammar cache
2. Disconnect from internet
3. Open a markdown file with Swift code block:
   ```markdown
   ```swift
   let greeting = "Hello"
   print(greeting)
   ```
   ```

**Expected:**
- Swift code is highlighted immediately
- No network requests
- Keywords, strings, etc. are colored

---

### 4. Unknown Language Fallback

**Purpose:** Verify unknown languages render as plain text without crashing.

**Steps:**
1. Open a markdown file with:
   ```markdown
   ```unknownlanguage
   this is unknown code
   ```
   ```

**Expected:**
- Code renders as plain text (no colors)
- No crash or error
- Code is properly escaped

---

### 5. Multiple Languages

**Purpose:** Verify multiple grammars can be loaded and used together.

**Steps:**
1. Clear grammar cache
2. Open a markdown file with multiple code blocks:
   ```markdown
   ```javascript
   const x = 1;
   ```

   ```python
   x = 1
   ```

   ```swift
   let x = 1
   ```
   ```

**Expected:**
- All three languages are highlighted
- JavaScript and Python download sequentially
- Swift works immediately (bundled)
- Each uses appropriate colors for its language

---

### 6. Network Failure Graceful Degradation

**Purpose:** Verify network failures don't break rendering.

**Steps:**
1. Clear grammar cache
2. Block network access to GitHub (e.g., hosts file or firewall)
3. Open a markdown file with Python code block

**Expected:**
- Python code renders as plain text
- No crash or hang
- Rest of document renders normally

---

### 7. Architecture Verification

**Purpose:** Verify universal binaries work on both architectures.

**Steps (Apple Silicon):**
1. Build and run on Apple Silicon Mac
2. Download JavaScript grammar
3. Verify highlighting works
4. Check binary: `file ~/Library/Application\ Support/SwiftMarkdown/Grammars/javascript/javascript.dylib`

**Steps (Intel):**
1. Build and run on Intel Mac (or via Rosetta)
2. Repeat above

**Expected:**
- Binary shows: `Mach-O universal binary with 2 architectures: [x86_64:Mach-O 64-bit dynamically linked shared library x86_64] [arm64]`
- Highlighting works on both architectures

---

### 8. Manifest Caching

**Purpose:** Verify manifest is cached and updated correctly.

**Steps:**
1. Clear grammar cache
2. Download any grammar
3. Check manifest: `cat ~/Library/Application\ Support/SwiftMarkdown/Grammars/manifest.json | head`
4. Close app
5. Reopen app and download different grammar

**Expected:**
- Manifest is cached
- Contains grammar metadata
- Second download uses cached manifest

---

## Environment Requirements

| Requirement | Test Scenarios |
|-------------|---------------|
| Internet connection | 1, 5 |
| No internet | 2, 3, 6 |
| Apple Silicon | 7 |
| Intel Mac | 7 |
| Fresh cache | 1, 3, 5, 6, 8 |

## Notes

- Grammar cache is permanent (no auto-expiration)
- Swift is always bundled (no download needed)
- All 36 languages supported via lazy-loading
- Grammars are universal binaries (arm64 + x86_64)
