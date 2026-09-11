# WO-XXXX: Checklist

## Prerequisites
- [ ] [Dependency WO] Complete
- [ ] [Required service/component] Available
- [ ] [Database migration] Run (if applicable)
- [ ] [Environment setup] Complete
- [ ] **Re-read CLAUDE.md** production quality standards

---

## MANDATORY: Pre-Implementation Quality Checklist

**Before writing any code, verify these requirements:**

### Configuration & Patterns
- [ ] Using configuration/settings instead of hardcoded values (no magic numbers)
- [ ] Following existing patterns in the codebase
- [ ] Using proper Logger service (not console.log)
- [ ] Error handling with proper exception types and messages

### Production Mindset
- [ ] "Would I deploy this to production right now?"
- [ ] "Would a code reviewer approve this?"
- [ ] "Does this match the quality of the existing codebase?"

---

## Phase 1: [Phase Name - e.g., Foundation]

### [Component/Feature 1]
- [ ] Create `[file path]`
- [ ] [Specific requirement 1]
- [ ] [Specific requirement 2]
- [ ] [Specific requirement 3]
- [ ] Tests written

### [Component/Feature 2]
- [ ] Create `[file path]`
- [ ] [Specific requirement 1]
- [ ] [Specific requirement 2]
- [ ] Tests written

---

## Phase 2: [Phase Name - e.g., Core Logic]

### [Component/Feature 3]
- [ ] Create `[file path]`
- [ ] [Specific requirement 1]
- [ ] [Specific requirement 2]
- [ ] Error handling implemented
- [ ] Tests written

### [Component/Feature 4]
- [ ] Create `[file path]`
- [ ] [Specific requirement 1]
- [ ] [Specific requirement 2]
- [ ] Tests written

---

## Phase 3: [Phase Name - e.g., Integration]

### [Integration Task 1]
- [ ] [Specific integration step 1]
- [ ] [Specific integration step 2]
- [ ] [Specific integration step 3]

### [Integration Task 2]
- [ ] [Specific integration step 1]
- [ ] [Specific integration step 2]

---

## Phase 4: Testing & Verification

### Unit Tests
- [ ] [Component 1] tests passing
- [ ] [Component 2] tests passing
- [ ] [Service 1] tests passing

### Integration Tests
- [ ] [Integration test 1] passing
- [ ] [Integration test 2] passing

### Manual Verification
- [ ] [Manual check 1]
- [ ] [Manual check 2]
- [ ] [Manual check 3]

---

---

## MANDATORY: Self-Review Before Declaring Done

**Complete ALL items before marking work as complete:**

### Code Quality Review
- [ ] Read through ALL changed files line by line
- [ ] Removed ALL console.log statements (use Logger service)
- [ ] No magic numbers - extracted to configuration or constants
- [ ] Proper typing - no `any` types, proper validation
- [ ] Error handling complete with clear messages

### Anti-Pattern Check
- [ ] Not just "tests passing" - reviewed actual implementation quality
- [ ] Didn't just patch the immediate problem - reviewed whole implementation
- [ ] Removed all debug/dev code after fixing issues
- [ ] Followed project standards in CLAUDE.md

### Production Readiness
- [ ] Would deploy this to production right now
- [ ] Code reviewer would approve this
- [ ] Matches quality of existing codebase

---

## Sign-Off

**Status:** Not Started | In Progress | Complete
**Date:**
**Implementer:**
**Reviewer:**

---

## Notes

[Add any implementation notes, discoveries, or issues encountered during implementation]
