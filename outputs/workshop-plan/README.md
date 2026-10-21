# TeamFlow workshop planning pack

Start with **IMPLEMENTATION_PLAN.md**. It defines the product, role permissions, BLoC conventions, file structure, 26 proposed API endpoints, mock services, go_router/deep links, team rules, build milestones and two six-hour teaching days.

The **client-requirements.xlsx** workbook contains five sheets: Requirements, Role access, Demo logins, API catalogue and Workshop schedule. Requirements are proposed scope, not signed client acceptance. The packaged ZIP places this workbook beside the plan.

Open **ui/index.html** to browse the proposed app screens. Import individual SVGs from **ui/** into Figma, or use **ui/teamflow-ui-board.svg** for the complete board. All 17 screen references are 390 × 844 and use editable vector shapes/text. SVG import does not create Auto Layout or a working prototype.

**mock_seed.json** contains 5 Employee, 3 Admin and 1 Super Admin accounts, 15 tasks, 15 work entries, teams, announcements and activity. The mock OTP is **123456** for every account. No real phone/API service is connected.

The app remains to be implemented. SVG-to-app parity, Flutter tests, platform deep links and package compatibility are implementation acceptance tasks. This planning delivery verifies the sample-data totals, workbook structure/formulas and SVG rendering.

Day 1 covers architecture, login and the employee read flow. Day 2 covers assignment, work updates, review, profiles, charts and access tests. A prepared starter and trainer reference app are required to fit the two-day schedule.
