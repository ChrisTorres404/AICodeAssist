#!/usr/bin/env bash
# stack-fixtures — build one minimal fixture per stack, install the pipeline into
# it, and assert what the install chose: rule sets, stack profile section, the
# Stack line in AGENTS.md, the run/test commands, and a clean doctor.
#
# PIPELINE_ROOT and EVAL_TMP are set by bin/eval. Exit non-zero to fail.
# Shortfalls in detection that do not (yet) justify failing are printed as
# KNOWN GAP lines; see README.md.
set -uo pipefail

ROOT="$PIPELINE_ROOT"
WORK="$EVAL_TMP/fixtures"
mkdir -p "$WORK"
FAILURES=0
GAPS=0

ok()   { printf '    ok    %s\n' "$*"; }
bad()  { printf '    FAIL  %s\n' "$*"; FAILURES=$((FAILURES + 1)); }
gap()  { printf '    KNOWN GAP  %s\n' "$*"; GAPS=$((GAPS + 1)); }

# w <relative-path>  — write stdin to the current fixture
w() { mkdir -p "$FX/$(dirname "$1")"; cat > "$FX/$1"; }

same() { # same <label> <expected> <actual>
  if [ "$2" = "$3" ]; then ok "$1"
  else bad "$1: expected [$2], got [$3]"; fi
}

# ---------------------------------------------------------------------------
# fixtures — marker files and one source file each; no toolchain is required
# ---------------------------------------------------------------------------
fx_nextjs() {
  w package.json <<'J'
{"name":"fx","private":true,
 "scripts":{"dev":"next dev","build":"next build","test":"vitest run","lint":"next lint"},
 "dependencies":{"next":"15.0.0","react":"18.3.1","react-dom":"18.3.1"}}
J
  w tsconfig.json <<<'{"compilerOptions":{"strict":true}}'
  w package-lock.json <<<'{"lockfileVersion":3}'
  w app/page.tsx <<<'export default function Page() { return null }'
}

fx_nestjs() {
  w package.json <<'J'
{"name":"fx","private":true,
 "scripts":{"start":"nest start","start:dev":"nest start --watch","build":"nest build","test":"jest"},
 "dependencies":{"@nestjs/core":"10.0.0","@nestjs/common":"10.0.0"}}
J
  w nest-cli.json <<<'{"collection":"@nestjs/schematics","sourceRoot":"src"}'
  w tsconfig.json <<<'{"compilerOptions":{"strict":true}}'
  w src/main.ts <<<'export class AppModule {}'
}

fx_vue() {
  w package.json <<'J'
{"name":"fx","private":true,"scripts":{"dev":"vite","build":"vite build","test":"vitest run"},
 "dependencies":{"vue":"3.4.0"}}
J
  w vue.config.js <<<'module.exports = {}'
  w src/App.vue <<<'<template><div /></template>'
}

fx_angular() {
  w package.json <<'J'
{"name":"fx","private":true,"scripts":{"start":"ng serve","build":"ng build","test":"ng test"},
 "dependencies":{"@angular/core":"18.0.0"}}
J
  w angular.json <<<'{"version":1,"projects":{}}'
  w tsconfig.json <<<'{"compilerOptions":{"strict":true}}'
  w src/main.ts <<<'export class AppComponent {}'
}

fx_svelte() {
  w package.json <<'J'
{"name":"fx","private":true,"scripts":{"dev":"vite dev","build":"vite build","test":"vitest run"},
 "devDependencies":{"svelte":"4.2.0"}}
J
  w svelte.config.js <<<'export default {}'
  w src/App.svelte <<<'<script>let a = 1</script>'
}

fx_remix() {
  w package.json <<'J'
{"name":"fx","private":true,"scripts":{"dev":"remix dev","build":"remix build","test":"vitest run"},
 "dependencies":{"@remix-run/react":"2.9.0","@remix-run/node":"2.9.0","react":"18.3.1"}}
J
  w remix.config.js <<<'module.exports = {}'
  w tsconfig.json <<<'{"compilerOptions":{"strict":true}}'
  w app/root.tsx <<<'export default function Root() { return null }'
}

fx_django() {
  w manage.py <<<'import django'
  w requirements.txt <<<'django==5.0.6'
  w myapp/views.py <<<'def index(request): return None'
}

fx_fastapi() {
  w pyproject.toml <<'P'
[project]
name = "fx"
version = "0.1.0"
dependencies = ["fastapi>=0.110", "uvicorn"]
P
  w app/main.py <<'P'
from fastapi import FastAPI
app = FastAPI()
P
  w tests/test_main.py <<<'def test_ok(): assert True'
}

fx_golang() {
  w go.mod <<'G'
module example.com/fx

go 1.22
G
  w cmd/server/main.go <<'G'
package main

func main() {}
G
}

fx_rust() {
  w Cargo.toml <<'C'
[package]
name = "fx"
version = "0.1.0"
edition = "2021"
C
  w src/main.rs <<<'fn main() {}'
}

fx_java_spring() {
  w pom.xml <<'X'
<project><modelVersion>4.0.0</modelVersion>
  <parent><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-parent</artifactId><version>3.3.0</version></parent>
  <groupId>com.fx</groupId><artifactId>fx</artifactId><version>0.1.0</version>
</project>
X
  w mvnw <<<'exit 0'
  chmod +x "$FX/mvnw"
  w src/main/resources/application.properties <<<'server.port=8080'
  w src/main/java/com/fx/App.java <<<'package com.fx; public class App {}'
}

fx_kotlin() {
  w build.gradle.kts <<<'plugins { kotlin("jvm") version "2.0.0" }'
  w src/main/kotlin/App.kt <<<'fun main() {}'
}

fx_rails() {
  w Gemfile <<'R'
source 'https://rubygems.org'
gem 'rails', '~> 7.1'
R
  w config/routes.rb <<<'Rails.application.routes.draw do end'
  w app/models/user.rb <<<'class User < ApplicationRecord; end'
}

fx_laravel() {
  w composer.json <<'C'
{"name":"fx/app","require":{"php":"^8.2","laravel/framework":"^11.0"}}
C
  w artisan <<<'<?php'
  w app/Http/Controllers/HomeController.php <<<'<?php class HomeController {}'
}

fx_flutter() {
  w pubspec.yaml <<'Y'
name: fx
environment:
  sdk: ">=3.4.0 <4.0.0"
dependencies:
  flutter:
    sdk: flutter
Y
  w lib/main.dart <<<'void main() {}'
}

fx_csharp() {
  w Fx.csproj <<<'<Project Sdk="Microsoft.NET.Sdk"><PropertyGroup><TargetFramework>net8.0</TargetFramework></PropertyGroup></Project>'
  w Program.cs <<<'class Program { static void Main() {} }'
}

fx_swift() {
  w Package.swift <<'S'
// swift-tools-version:5.9
import PackageDescription
let package = Package(name: "Fx")
S
  w Sources/App/main.swift <<<'print("hi")'
}

# ---------------------------------------------------------------------------
# one stack: build, install, assert
#   stack <name> <builder> <rules> <profile-heading> <stack-line> <run> <test>
# an empty <profile-heading> means no stack profile ships for this stack
# ---------------------------------------------------------------------------
stack() {
  local name="$1" builder="$2" want_rules="$3" want_profile="$4" want_line="$5" want_run="$6" want_test="$7"
  printf '  %s\n' "$name"
  FX="$WORK/$name"; mkdir -p "$FX"
  "$builder"

  sed -e 's/^export PROJECT_NAME=.*/export PROJECT_NAME="Fixture '"$name"'"/' \
      -e 's/^export PROJECT_SLUG=.*/export PROJECT_SLUG="fixture-'"$name"'"/' \
      "$ROOT/pipeline.config.example.sh" > "$FX/pipeline.config.sh"

  if ! "$ROOT/bin/install.sh" "$FX" > "$FX/.install.log" 2>&1; then
    bad "install failed: $(tail -3 "$FX/.install.log" | tr '\n' ' ')"; return
  fi

  same "rule sets" "$want_rules" "$(ls "$FX/.claude/rules" 2>/dev/null | sort | tr '\n' ' ' | sed 's/ $//')"

  local heading
  heading="$(grep -m1 '^## Stack Rules — ' "$FX/AGENTS.md" 2>/dev/null || true)"
  same "stack profile" "$want_profile" "$heading"

  same "Stack line" "$want_line" "$(grep -m1 '^- \*\*Stack:\*\*' "$FX/AGENTS.md" 2>/dev/null || true)"

  local json; json="$("$ROOT/bin/detect-stack" "$FX" --json 2>/dev/null || echo '{}')"
  same "run command"  "$want_run"  "$(printf '%s' "$json" | cmd_of run)"
  same "test command" "$want_test" "$(printf '%s' "$json" | cmd_of test)"

  if "$FX/.aicodepipeline/bin/acp" doctor "$FX" 2>&1 | grep -q 'FAIL'; then
    bad "doctor reported FAIL"
    "$FX/.aicodepipeline/bin/acp" doctor "$FX" 2>&1 | grep 'FAIL' | sed 's/^/      /'
  else
    ok "doctor: no FAIL"
  fi
}

cmd_of() { python3 -c 'import json,sys; print(json.load(sys.stdin).get("commands",{}).get(sys.argv[1],""))' "$1" 2>/dev/null || true; }

# ---------------------------------------------------------------------------
#      name         builder         rule sets                            stack profile heading                         Stack line                                                  run                          test
# ---------------------------------------------------------------------------
stack nextjs      fx_nextjs      "common react typescript ui web" "## Stack Rules — Next.js (App Router)" '- **Stack:** typescript, nextjs, react (npm)'      'npm run dev'                'npm run test'
stack nestjs      fx_nestjs      "common typescript"              "## Stack Rules — NestJS"                '- **Stack:** typescript, nestjs (npm)'             'npm run start'              'npm run test'
stack vue         fx_vue         "common typescript ui vue web"   "## Stack Rules — Vue 3"                         '- **Stack:** javascript, vue (npm)'                 'npm run dev'                'npm run test'
stack angular     fx_angular     "angular common typescript ui web" "## Stack Rules — Angular"                       '- **Stack:** typescript, angular (npm)'             'npm run start'              'npm run test'
stack svelte      fx_svelte      "common typescript ui web"       "## Stack Rules — Svelte / SvelteKit"            '- **Stack:** javascript, svelte (npm)'              'npm run dev'                'npm run test'
stack remix       fx_remix       "common react typescript ui web" "## Stack Rules — Remix"                         '- **Stack:** typescript, react, remix (npm)'        'npm run dev'                'npm run test'
stack django      fx_django      "common python"                  "## Stack Rules — Python (Django / FastAPI / services)" '- **Stack:** python, django (pip)'                  'python manage.py runserver' 'python manage.py test'
stack fastapi     fx_fastapi     "common python"                  "## Stack Rules — Python (Django / FastAPI / services)" '- **Stack:** python, fastapi (pip)' 'uvicorn app.main:app --reload' 'pytest'
stack golang      fx_golang      "common golang"                  "## Stack Rules — Go"                    '- **Stack:** golang (go)'                          'go run ./cmd/server'        'go test ./...'
stack rust        fx_rust        "common rust"                    "## Stack Rules — Rust"                  '- **Stack:** rust (cargo)'                         'cargo run'                  'cargo test'
stack java-spring fx_java_spring "common java"                    "## Stack Rules — Java (Spring Boot / JVM services)" '- **Stack:** java, spring (maven)'                  './mvnw spring-boot:run'     './mvnw test'
stack kotlin      fx_kotlin      "common java kotlin"             "## Stack Rules — Kotlin (Ktor / Spring / Android)" '- **Stack:** kotlin, java (gradle)'                 'gradle run'                 'gradle test'
stack rails       fx_rails       "common ruby"                    "## Stack Rules — Ruby (Rails)"         '- **Stack:** ruby, rails (bundler)'                'bundle exec rails server'   'bundle exec rspec'
stack laravel     fx_laravel     "common php"                     "## Stack Rules — PHP (Laravel)"         '- **Stack:** php, laravel (composer)'              'php artisan serve'          'vendor/bin/phpunit'
stack flutter     fx_flutter     "common dart ui web"             "## Stack Rules — Flutter / Dart"                '- **Stack:** dart, flutter (pub)'                   'flutter run'                'flutter test'
stack csharp      fx_csharp      "common csharp"                  "## Stack Rules — C# (.NET services)"            '- **Stack:** csharp (dotnet)'                       'dotnet run'                 'dotnet test'
stack swift       fx_swift       "common swift"                   "## Stack Rules — Swift (server or app)"         '- **Stack:** swift (swiftpm)'                       'swift run'                  'swift test'
# ---------------------------------------------------------------------------
# Gaps: knowable from the markers in the fixture, not yet emitted by
# bin/detect-stack. Recorded, not failed — bin/ is owned elsewhere.
# ---------------------------------------------------------------------------
echo
echo "  gaps in detection (not failures):"
gap "svelte, nestjs, nextjs, remix, express: no rule set ships in core/rules/, so these frameworks contribute only their language's rules."
gap "svelte and vue fixtures report the language as javascript because neither carries a tsconfig.json; the installed rule set is typescript either way."

echo
if [ "$FAILURES" -gt 0 ]; then
  echo "  $FAILURES assertion(s) failed, $GAPS known gap(s)"
  exit 1
fi
echo "  all stacks asserted, $GAPS known gap(s)"
exit 0
