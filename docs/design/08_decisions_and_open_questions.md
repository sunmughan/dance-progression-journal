# 08 Decisions and Open Questions

## Decisions made in this design pass

1. Accent colour is provisional teal #0E7A5F, taken from the Week 1
   presentation. It is a single token swap when May gives her brand
   preference, due 2 Dec 2026. No layout depends on the accent value.
2. Dances have no colour. A dance is always named in words. This keeps
   the app clean and keeps VoiceOver honest.
3. Cards are for widgets and settings groups only. Lists are rows with
   dividers. This follows the Astryx frame first rule and keeps the app
   from looking like a stack of boxes.
4. Tab map: Journal tab root is Home Dashboard. Library tab root is Video
   Library with a top segment for Figures and Drills. Progress tab root
   is Journal Insights with a top segment for Practice History. This
   keeps four tabs and twenty screens with no extra root screen invented.
5. Admin lives inside the app in Phase 1, reached from Settings through
   Content Management, because Phase 1 is local only with no backend and
   no account. Admin edits change the on device library data directly.
6. Difficulty options are Beginner, Intermediate, Advanced. The roadmap
   names a difficulty selector without values. These three are the
   default. See open question 4.
7. Practice sessions cannot be edited in Phase 1. A wrong session is
   deleted from Practice History by swiping the row, then logged again.
   Edit for practice sessions is a Phase 2 candidate.
8. Delete confirmations use alerts with the object named in the question.
   Cancel on a form with entered text discards without confirmation, per
   standard iOS form behaviour.
9. Dates in sample data are relative: Today, Yesterday, 2 days ago. The
   app shows real calendar dates in production use. Relative labels keep
   the specs free of invented calendar dates.
10. The sample NDCA competition is shown only as a relative countdown,
    labelled sample data, with no real name, date, venue or price.
11. The countdown shows days, hours and minutes only. No live seconds
    ticker.
12. `textTertiary` in light mode measures 4.2 to 1, so it is restricted to
    large text at 17 pt and above and to icons. It is never used for
    footnote or caption sizes.
13. The timer on Drill Detail is a simple count up timer on the detail
    screen, not a separate screen. The roadmap lists Start Timer as a
    control, not as a screen.

## Open questions for the client

1. Brand preference, due 2 Dec 2026. Colours, app display name, icon
   preference, any reference images. Blocks the final accent token only.
   Everything else can be built now.
2. NDCA figure list source, due 9 Dec 2026. Official list, PDF or link
   for International Latin figures. Blocks the real library content. The
   library is built now with sample figures labelled pending the client
   list.
3. Competition dates, due 16 Dec 2026. Next two competitions with dates,
   locations and checklist items. Blocks real countdown content. The
   screens are built now with the sample event.
4. Difficulty values. Is Beginner, Intermediate, Advanced right, or does
   May use Bronze, Silver, Gold, Gold Star for drills too? Default in
   this spec is Beginner, Intermediate, Advanced.
5. Admin access. In Phase 1 the admin screens sit behind Settings with no
   gate, because there is no account. Does May want any local gate, such
   as a simple passcode, on Content Management? Default in this spec is
   no gate. A gate is a small addition if she asks for it.
6. Library and Progress tab segments. The segment approach keeps four
   tabs with no extra root screen. Does May prefer separate tab items or
   the segment? Default in this spec is the segment.
7. Instagram handle, due 10 Dec 2026. Exact handle and link format.
   Blocks only the real Instagram buttons. The buttons are built now and
   hidden when no link is set.
8. Sample videos, due 9 Dec 2026. Three to five sample videos with date
   and type, for upload testing. Blocks device testing of real video
   sizes. The upload flow is built now with the sample data set.

## Notes for the build team

- Build `DesignTokens.swift` first, then components, then screens.
- Do not add screens. Do not add features. If a screen needs something
  the roadmap does not name, raise it instead of building it.
- The Week 1 milestone is 2 Dec 2026: working journal flow on a test
  device. Screens 1 to 5 first, in that order, then the rest.
- The flow diagram in the goal folder,
  `dance_progression_journal_flow_2026_11_26.png`, matches the five flows
  in `07_ux_flows.md`. If they ever disagree, the flows file wins and the
  diagram is redrawn.
