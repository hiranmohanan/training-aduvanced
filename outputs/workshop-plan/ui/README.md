# TeamFlow SVG handoff

These 17 screens define the proposed Flutter UI. They are not screenshots of an implemented app.

- Import individual SVG files into Figma, or import teamflow-ui-board.svg for the full collection.
- Every individual screen uses a 390 × 844 viewBox. Use the same logical viewport for Flutter comparisons.
- Text uses Arial (system font reference). No fonts or photos are embedded. Shapes, icons and text remain vector objects. Figma may need the same font installed.
- SVG import creates vector/text artwork; set up components, Auto Layout and prototype interactions separately.
- Main designs show populated states. Add loading, empty, failure, access-denied and validation states as specified in the requirements.
- Use mock_seed.json and the fixed demo clock for matching content. Assign-task and review forms are drafts, not saved fixture records.
- A profile viewed by an Admin reuses the employee profile layout with an Employee profile title and appropriate navigation. Team-filtered reports reuse the reports layout with derived team values.
- The role edit screen is a sheet/page opened from User management. The UI builder treats it as a separate frame for handoff.
- Company/settings links and task actions should be implemented through visible overflow menus or the profile/settings actions; add those menus when wiring the app.
- Body content scrolls when needed. Preserve 48 px minimum interactive targets even when an icon or chip is visually smaller.

## Screen map

| SVG | Screen | Route / context | Role |
|---|---|---|---|
| 01-phone-sign-in.svg | Phone sign-in | /login | All |
| 02-verify-code.svg | Verify code | /verify | All |
| 03-employee-dashboard.svg | Employee dashboard | /home | Employee |
| 04-admin-dashboard.svg | Admin dashboard | /home | Admin |
| 05-super-admin-dashboard.svg | Super Admin dashboard | /home | Super Admin |
| 06-task-list.svg | Task list | /tasks | Employee |
| 07-task-detail.svg | Task detail | /tasks/T001 | Employee |
| 08-work-update.svg | Work update | /tasks/T001/update | Employee |
| 09-assign-task.svg | Assign task | /tasks/new | Admin |
| 10-employee-profile.svg | Employee profile | /profile | Employee; scoped admin view |
| 11-company-reports.svg | Company reports | /reports | Super Admin |
| 12-employee-directory.svg | Employee directory | /employees | Super Admin; admin uses team filter |
| 13-user-management.svg | User management | /admin/users | Super Admin |
| 14-edit-user-access.svg | Edit user access | /admin/users · edit sheet | Super Admin |
| 15-company-and-announcements.svg | Company and announcements | /company | All |
| 16-settings-and-about.svg | Settings and about | /settings | All |
| 17-admin-task-review.svg | Admin task review | /tasks/T005 | Admin |

## Tokens

| Token | Value |
|---|---|
| bg | #F5F7FB |
| white | #FFFFFF |
| navy | #152842 |
| text | #233550 |
| muted | #66758C |
| line | #DFE5EE |
| blue | #315EEB |
| pale | #EAF0FF |
| green | #16764D |
| greenBg | #E6F5ED |
| amber | #996209 |
| amberBg | #FFF3D9 |
| red | #B44242 |
| redBg | #FCEBEB |
| purple | #6B4FC0 |
| purpleBg | #F0EBFA |

Page margin: 20 px. Cards: 16 px radius. Inputs/buttons: 12 px radius. Primary button: 52 px tall. Body text: 14 px. Main titles: 27 px. Main bottom navigation: 78 px including safe area.
