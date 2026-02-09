#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
JS_ROOT="$(cd "$REPO_ROOT/../algotrade-js-trial" && pwd)"

JS_OUT="$SCRIPT_DIR/js_output.json"
SWIFT_OUT="$SCRIPT_DIR/swift_output.json"
SWIFT_BIN="$SCRIPT_DIR/swift_runner_bin"

pushd "$REPO_ROOT" >/dev/null
xcodebuild -scheme BacktestingKit -project BacktestingKit.xcodeproj -configuration Debug CODE_SIGNING_ALLOWED=NO build >/tmp/backtestingkit_parity_build.log
popd >/dev/null

cd "$JS_ROOT"
npx -y tsx "$SCRIPT_DIR/js_runner.ts" > "$JS_OUT"

SWIFT_FRAMEWORK_DIR="/Users/fung/Library/Developer/Xcode/DerivedData/BacktestingKit-fphocypahkabhccfcjtlxooemiie/Build/Products/Debug"
swiftc "$SCRIPT_DIR/swift_runner.swift" \
  -I "$SWIFT_FRAMEWORK_DIR" \
  -F "$SWIFT_FRAMEWORK_DIR" \
  -L "$SWIFT_FRAMEWORK_DIR" \
  -framework BacktestingKit \
  -Xlinker -rpath -Xlinker "$SWIFT_FRAMEWORK_DIR" \
  -o "$SWIFT_BIN"

"$SWIFT_BIN" > "$SWIFT_OUT"

node - "$JS_OUT" "$SWIFT_OUT" <<'NODE'
const fs=require('fs');
const a=JSON.parse(fs.readFileSync(process.argv[2],'utf8'));
const b=JSON.parse(fs.readFileSync(process.argv[3],'utf8'));
function cmp(x,y,path='root'){
  if(typeof x!==typeof y) throw new Error(`${path} type mismatch ${typeof x} vs ${typeof y}`);
  if(x===null||y===null){ if(x!==y) throw new Error(`${path} null mismatch`); return; }
  if(Array.isArray(x)){
    if(x.length!==y.length) throw new Error(`${path} length mismatch ${x.length} vs ${y.length}`);
    for(let i=0;i<x.length;i++) cmp(x[i],y[i],`${path}[${i}]`);
    return;
  }
  if(typeof x==='object'){
    const kx=Object.keys(x).sort();
    const ky=Object.keys(y).sort();
    if(kx.join('|')!==ky.join('|')) throw new Error(`${path} keys mismatch ${kx} vs ${ky}`);
    for(const k of kx) cmp(x[k],y[k],`${path}.${k}`);
    return;
  }
  if(typeof x==='number'){
    const eps=Math.max(1e-9, Math.abs(x)*1e-9);
    if(Math.abs(x-y)>eps) throw new Error(`${path} number mismatch ${x} vs ${y}`);
    return;
  }
  if(x!==y) throw new Error(`${path} mismatch ${x} vs ${y}`);
}
cmp(a,b);
console.log('PARITY_OK');
NODE

echo "Parity check passed."
