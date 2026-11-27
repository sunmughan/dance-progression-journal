#!/bin/bash
# Captures one real screenshot per screen by launching the real app in the
# booted simulator with screenshot launch arguments, then simctl screenshot.
# Usage: bash tools/capture-screens.sh user|admin
# Needs SIM_UDID set to the booted simulator, and the app already built.
set -euo pipefail

APP_KIND="${1:?user or admin}"
SIM_UDID="${SIM_UDID:?booted simulator udid}"
OUT="screenshots/$APP_KIND"
mkdir -p "$OUT"

if [ "$APP_KIND" = user ]; then
  APP_PATH="DerivedData/Build/Products/Debug-iphonesimulator/DanceProgressionJournal.app"
  BUNDLE_ID="com.codeair.danceprogressionjournal"
  SCREENS="welcome home journalList entryDetail entryFormNew entryFormEdit insights practiceHistory drillList drillDetail drillFormNew drillFormEdit videoLibrary videoDetail videoFormNew videoFormEdit competitionList competitionDetail competitionFormNew competitionFormEdit figureLibrary figureDetail figurePracticeForm settings"
else
  APP_PATH="DerivedDataAdmin/Build/Products/Debug-iphonesimulator/DanceProgressionJournalAdmin.app"
  BUNDLE_ID="com.codeair.danceprogressionjournal.admin"
  SCREENS="dashboard manageFigures figureFormNew figureFormEdit manageCompetitions competitionFormEdit manageDrills drillFormEdit contentCategories appSettings"
fi

xcrun simctl install "$SIM_UDID" "$APP_PATH"

for screen in $SCREENS; do
  xcrun simctl terminate "$SIM_UDID" "$BUNDLE_ID" 2>/dev/null || true
  if [ "$screen" = welcome ]; then
    SETUP_FLAG=NO
  else
    SETUP_FLAG=YES
  fi
  xcrun simctl launch "$SIM_UDID" "$BUNDLE_ID" \
    -screenshotSeed -screenshotScreen "$screen" \
    -DanceProgressionJournal.hasCompletedSetup "$SETUP_FLAG"
  sleep 5
  xcrun simctl io "$SIM_UDID" screenshot "$OUT/$screen.png"
  echo "captured $APP_KIND/$screen"
done
