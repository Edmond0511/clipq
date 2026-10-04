#!/usr/bin/env node
const { execFileSync, spawnSync } = require("child_process");
const path = require("path");

const APP = path.join(__dirname, "dist", "Clipq.app");
const BINARY = path.join(APP, "Contents", "MacOS", "Clipq");

function isRunning() {
  return spawnSync("pgrep", ["-f", BINARY]).status === 0;
}

const commands = {
  start() {
    if (isRunning()) return console.log("clipq is already running.");
    execFileSync("open", [APP]);
    console.log("clipq started. Press Cmd+Shift+V to open your clipboard history.");
  },
  stop() {
    if (!isRunning()) return console.log("clipq is not running.");
    spawnSync("pkill", ["-f", BINARY]);
    console.log("clipq stopped.");
  },
  status() {
    console.log(isRunning() ? "clipq is running." : "clipq is not running.");
  },
  "enable-login"() {
    execFileSync(BINARY, ["--enable-login"]);
    console.log("clipq will start at login.");
  },
  "disable-login"() {
    execFileSync(BINARY, ["--disable-login"]);
    console.log("clipq will no longer start at login.");
  },
};

const command = commands[process.argv[2]];
if (!command) {
  console.log(`Usage: clipq <${Object.keys(commands).join(" | ")}>`);
  process.exit(process.argv[2] ? 1 : 0);
}
command();
