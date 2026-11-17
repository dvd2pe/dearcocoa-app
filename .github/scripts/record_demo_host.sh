#!/usr/bin/env bash
# Host-side orchestration for the DearCocoa demo recording (GitHub Actions).
# Boots an Android emulator, starts the screencap loop + screenrecord video,
# runs the walkthrough integration test, then collects logs and videos.
set -uo pipefail

ADB="$ANDROID_HOME/platform-tools/adb"
SHOTS_DIR="${SHOTS_DIR:-$PWD/demo/shots}"
ART_DIR="${ART_DIR:-$PWD/demo}"
mkdir -p "$SHOTS_DIR"

sdkmanager() { "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" "$@"; }

echo "== KVM check =="
ls -l /dev/kvm 2>/dev/null || echo "WARN: /dev/kvm not found (emulator will be slow)"

echo "== Install emulator bits =="
yes | sdkmanager --licenses >/dev/null 2>&1 || true
sdkmanager "platform-tools" "emulator" "system-images;android-30;google_apis;x86_64" >/dev/null

echo "== Create AVD =="
echo "no" | "$ANDROID_HOME/cmdline-tools/latest/bin/avdmanager" create avd \
  -n demo -k "system-images;android-30;google_apis;x86_64" -d pixel || true

echo "== Boot emulator =="
"$ANDROID_HOME/emulator/emulator" -avd demo \
  -no-window -gpu swiftshader_indirect -no-snapshot -no-audio \
  -no-boot-anim -accel on -memory 3072 &
EMU_PID=$!

"$ADB" wait-for-device
for i in $(seq 1 120); do
  if [ "$("$ADB" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ]; then
    echo "boot completed after ~$((i*3))s"
    break
  fi
  sleep 3
done
# slower UI so every screen is captured at least once
"$ADB" shell settings put global window_animation_scale 1.0
"$ADB" shell settings put global transition_animation_scale 1.0
"$ADB" shell settings put global animator_duration_scale 1.0

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
set -e
flutter test integration_test/demo_walkthrough_test.dart -d emulator-5554 \
  --flavor prod \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  2>&1 | tee "$ART_DIR/flutter_test_log.txt" || TEST_FAILED=1
set +e

echo "== Stop capture =="
kill "$CAP_PID" 2>/dev/null || true
"$ADB" shell pkill -INT screenrecord 2>/dev/null || true
sleep 4

echo "== Collect logs and videos =="
"$ADB" logcat -d > "$ART_DIR/logcat.txt" 2>/dev/null || true
for i in 1 2 3 4; do
  "$ADB" pull "/sdcard/demo_$i.mp4" "$ART_DIR/" 2>/dev/null || true
done

# flutter test runner was killed if TEST_FAILED; emulator keeps running
echo "WALKTHROUGH_DONE"
