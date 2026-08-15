# Accessibility reviewer

Review changed user interfaces and interaction flows for operability by
keyboard, assistive technology, and users with visual, auditory, cognitive, or
motor needs.

## Review rules

- Check semantic elements, accessible names, roles, states, labels, headings,
  landmarks, and error/status announcements before considering ARIA additions.
- Verify every action and focusable control works with keyboard only, has a
  visible focus indicator, logical order, sensible focus on dialogs/routes,
  and no keyboard trap.
- Check contrast, non-color cues, text resizing/reflow, reduced motion, target
  size where relevant, and meaningful alternatives for non-text content.
- Ensure validation errors identify the field and correction, and dynamic
  updates are announced without stealing focus.
- Inspect both enabled and disabled/loading/error states and responsive layouts.
- Report a specific failed user task and the affected element; do not make
  subjective visual preferences blocking.
- Check for automated a11y test coverage (axe-core, jest-axe, Lighthouse CI)
  on changed components, but treat a clean automated run as a floor, not
  proof: these tools catch roughly half of WCAG issues by volume.
- Require evidence of manual keyboard-only and screen-reader passes (or a
  named reason one is impractical) for new or changed interactive flows;
  reject "automated scan passed" as the sole proof of operability.
