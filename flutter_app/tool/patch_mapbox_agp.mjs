#!/usr/bin/env node
/**
 * mapbox_maps_flutter 2.28.0 skips `kotlin-android` under AGP 9+ but still uses
 * a `kotlin {}` block. With `android.builtInKotlin=false` that breaks evaluation.
 * Re-apply the plugin unconditionally after `flutter pub get`.
 */
import { readFileSync, writeFileSync, existsSync } from "node:fs";
import { join } from "node:path";
import { homedir } from "node:os";

const gradle = join(
  process.env.LOCALAPPDATA || join(homedir(), "AppData", "Local"),
  "Pub",
  "Cache",
  "hosted",
  "pub.dev",
  "mapbox_maps_flutter-2.28.0",
  "android",
  "build.gradle",
);

if (!existsSync(gradle)) {
  console.log("mapbox patch: package not found, skip");
  process.exit(0);
}

let src = readFileSync(gradle, "utf8");
const original = src;
src = src.replace(
  /def agpMajor = com\.android\.Version\.ANDROID_GRADLE_PLUGIN_VERSION\.tokenize\('\.'\)\[0\] as int\s*\nif \(agpMajor < 9\) \{\s*\n\s*apply plugin: 'kotlin-android'\s*\n\}/,
  "apply plugin: 'kotlin-android'",
);
if (src === original) {
  if (src.includes("apply plugin: 'kotlin-android'") && !src.includes("agpMajor < 9")) {
    console.log("mapbox patch: already applied");
    process.exit(0);
  }
  console.log("mapbox patch: pattern not found — check package version");
  process.exit(0);
}
writeFileSync(gradle, src);
console.log("mapbox patch: applied kotlin-android unconditional");
