#!/bin/bash
set -e

# Ensure environment files exist for flutter assets
cp -n .env.example .env 2>/dev/null || true
cp -n .env.example .env.dev 2>/dev/null || true
cp -n .env.example .env.prod 2>/dev/null || true

# Clone Flutter stable if not already cached
if [ ! -d "flutter" ]; then
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable flutter
fi

# Build Flutter Web in release mode
export PATH="$PATH:`pwd`/flutter/bin"
flutter config --no-analytics
flutter config --enable-web
flutter pub get
flutter build web --release --base-href /

# Ensure static legal pages, sitemap, robots, and verification files are in build/web
cp -f web/sitemap.xml build/web/ 2>/dev/null || true
cp -f web/robots.txt build/web/ 2>/dev/null || true
cp -f web/google*.html build/web/ 2>/dev/null || true
mkdir -p build/web/legal
cp -rf web/legal/* build/web/legal/ 2>/dev/null || true
