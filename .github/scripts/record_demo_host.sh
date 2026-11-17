#!/usr/bin/env bash
# Host-side orchestration for the DearCocoa demo recording (GitHub Actions).
# Boots an Android emulator, starts the screencap loop + screenrecord video,
# runs the walkthrough integration test, then collects logs and videos.
#
# The AVD is created MANUALLY (ini files): avdmanager hangs on runners.
# Every long step is capped with `timeout` so the job never hangs forever.
set -uo pipefail

ADB="$ANDROID_HOME/platform-tools/adb"
SHOTS_DIR="${SHOTS_DIR:-$PWD/demo/shots}"
ART_DIR="${ART_DIR:-$PWD/demo}"
mkdir -p "$SHOTS_DIR"

sdkmanager() { "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" "$@"; }

echo "== KVM check =="
ls -l /dev/kvm 2>/dev/null || echo "WARN: /dev/kvm not found (emulator will be slow)"

echo "== Install emulator bits =="
SDKM="$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager"
yes | timeout 120 "$SDKM" --licenses >/dev/null 2>&1 || true
timeout 900 "$SDKM" "platform-tools" "emulator" \
  "system-images;android-30;google_apis;x86_64" >/dev/null
ls "$ANDROID_HOME/emulator/emulator" >/dev/null || { echo "FATAL: emulator binary missing" >&2; exit 1; }
ls "$ANDROID_HOME/system-images/android-30/google_apis/x86_64" >/dev/null \
  || { echo "FATAL: system image missing" >&2; exit 1; }
echo "sdk bits installed"

echo "== Create AVD manually (avdmanager hangs on runners) =="
AVD_HOME="${ANDROID_AVD_HOME:-$HOME/.android/avd}"
mkdir -p "$AVD_HOME/demo.avd"
cat > "$AVD_HOME/demo.ini" <<EOF
avd.ini.encoding=UTF-8
path=$AVD_HOME/demo.avd
path.rel=avd/demo.avd
target=android-30
EOF
cat > "$AVD_HOME/demo.avd/config.ini" <<EOF
avd.ini.encoding=UTF-8
abi.type=x86_64
hw.cpu.arch=x86_64
hw.cpu.ncore=4
hw.lcd.density=420
hw.lcd.height=2340
hw.lcd.width=1080
hw.ramSize=3072
hw.keyboard=yes
image.sysdir.1=system-images/android-30/google_apis/x86_64/
tag.id=google_apis
tag.displayName=Google APIs
disk.dataPartition.size=6G
hw.gpu.enabled=yes
hw.gpu.mode=swiftshader_indirect
EOF
echo "AVD written to $AVD_HOME/demo.avd"

echo "== Boot emulator =="
"$ANDROID_HOME/emulator/emulator" -avd demo \
  -no-window -gpu swiftshader_indirect -no-snapshot -no-audio \
  -no-boot-anim -accel on -no-metrics &
EMU_PID=$!

# fail fast if the emulator process dies
sleep 10
if ! kill -0 "$EMU_PID" 2>/dev/null; then
  echo "FATAL: emulator process died immediately" >&2
  exit 1
fi

timeout 600 "$ADB" wait-for-device || { echo "FATAL: adb wait-for-device timeout" >&2; exit 1; }

BOOTED=0
for i in $(seq 1 100); do
  if ! kill -0 "$EMU_PID" 2>/dev/null; then
    echo "FATAL: emulator died during boot (after ~$((i*3))s)" >&2
    exit 1
  fi
  if [ "$("$ADB" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ]; then
    echo "boot completed after ~$((i*3))s"
    BOOTED=1
    break
  fi
  sleep 3
done
[ "$BOOTED" = "1" ] || { echo "FATAL: boot incomplete" >&2; exit 1; }

"$ADB" shell settings put global window_animation_scale 1.0
"$ADB" shell settings put global transition_animation_scale 1.0
"$ADB" shell settings put global animator_duration_scale 1.0
"$ADB" shell "logcat -c" 2>/dev/null || true

echo "== Start capture loop (screenshots every 2s) + screenrecord segments =="
(
  while true; do
    "$ADB" exec-out screencap -p > "$SHOTS_DIR/f_$(date +%s).png" 2>/dev/null || true
    sleep 2
  done
) &
CAP_PID=$!

(
  for i in 1 2 3 4; do
    "$ADB" shell screenrecord --time-limit 170 --bit-rate 6000000 "/sdcard/demo_$i.mp4" || true
  done
) &
REC_PID=$!

echo "== Run walkthrough integration test =="
timeout 1500 flutter test integration_test/demo_walkthrough_test.dart \
  -d emulator-5554 \
  --flavor prod \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  2>&1 | tee "$ART_DIR/flutter_test_log.txt" || TEST_FAILED=1
grep -q "All tests passed" "$ART_DIR/flutter_test_log.txt" || TEST_FAILED=1
if [ "${TEST_FAILED:-0}" = "1" ]; then
  echo "WARNING: walkthrough did not fully pass (artifacts still collected)"
else
  echo "walkthrough passed"
fi

echo "== Stop capture =="
kill "$CAP_PID" 2>/dev/null || true
"$ADB" shell pkill -INT screenrecord 2>/dev/null || true
sleep 4

echo "== Collect logs and videos =="
"$ADB" logcat -d > "$ART_DIR/logcat.txt" 2>/dev/null || true
for i in 1 2 3 4; do
  "$ADB" pull "/sdcard/demo_$i.mp4" "$ART_DIR/" 2>/dev/null || true
done
ls -la "$ART_DIR"

echo "WALKTHROUGH_DONE"
