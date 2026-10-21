abstract final class AppText {
  static const home = 'Home',
      tasks = 'Tasks',
      reports = 'Reports',
      profile = 'Profile';
  static const company = 'Company',
      settings = 'Settings',
      employees = 'Employees';
  static const signInTitle = 'Your team.\nOne clear workspace.';
  static const signInSubtitle =
      'Tasks, progress and people,\nall in one place.';
  static const phone = 'Work phone number', sendCode = 'Send verification code';
  static const demoAccounts = 'Try a demo account',
      noSms = 'Demo mode · no SMS will be sent';
  static const verifyTitle = 'Verify your number',
      otpLabel = 'Verification code';
  static const verify = 'Verify and sign in',
      resend = 'Resend code',
      changePhone = 'Change phone';
  static const demoOtp =
      'Use 123456 for every demo account.\nYour phone determines your role.';
  static const logout = 'Log out',
      retry = 'Try again',
      cancel = 'Cancel',
      save = 'Save';
  static const all = 'All', active = 'Active', done = 'Done', todo = 'Todo';
  static const inProgress = 'In progress',
      inReview = 'In review',
      blocked = 'Blocked';
  static const low = 'Low', medium = 'Medium', high = 'High';
  static const employee = 'Employee',
      admin = 'Admin',
      superAdmin = 'Super Admin';
  static const myTasks = 'My tasks',
      teamOverview = 'Team overview',
      companyOverview = 'Company overview';
  static const assigned = 'Assigned tasks',
      activeTasks = 'Active tasks',
      completed = 'Completed';
  static const weeklyHours = 'Hours this week',
      overdue = 'Overdue',
      currentTasks = 'Current tasks';
  static const viewAll = 'View all',
      yourWeek = 'Your work week',
      teamHours = 'Team work hours';
  static const taskStatus = 'Task status',
      dailyHours = 'Daily logged hours',
      completion = 'Task completion';
  static const loggedHours = 'Logged hours',
      closedEntries = 'Closed work entries',
      currentWeek = 'Current week';
  static const reviewQueue = 'Waiting for review',
      yourTeams = 'Your teams',
      manageUsers = 'Manage users';
  static const assignTask = 'Assign task',
      taskTitle = 'Task title',
      description = 'Description';
  static const assignTo = 'Assign to',
      priority = 'Priority',
      dueDate = 'Due date';
  static const searchTasks = 'Search your tasks',
      searchPeople = 'Search people';
  static const taskDetails = 'Task details',
      taskProgress = 'Task progress',
      recentActivity = 'Recent activity';
  static const updateWork = 'Update work',
      status = 'Status',
      workUpdate = 'Work update';
  static const blocker = 'Blocker reason',
      timeTracking = 'Time tracking',
      noTimer = 'No timer running';
  static const startTimer = 'Start timer',
      stopTimer = 'Stop timer',
      manualTime = 'Add time manually';
  static const startTime = 'Start time',
      endTime = 'End time',
      workNote = 'Work note';
  static const saveUpdate = 'Save update', submitReview = 'Submit for review';
  static const reviewTask = 'Review task', reviewComment = 'Review comment';
  static const approve = 'Approve',
      requestChanges = 'Request changes',
      reassign = 'Reassign task';
  static const myProfile = 'My profile',
      employeeProfile = 'Employee profile',
      reportingTo = 'Reporting to';
  static const joined = 'Joined',
      workHistory = 'Recent work entries',
      noWork = 'No work logged yet';
  static const userManagement = 'User management',
      editAccess = 'Edit access',
      role = 'Role';
  static const managedTeam = 'Managed team',
      accountActive = 'Account active',
      saveAccess = 'Save access';
  static const accessHint =
      'Changes apply on the next sign-in.\nTask history stays with the same user.';
  static const announcements = 'Announcements', ourTeams = 'Our teams';
  static const workNotAttendance =
      'Task time is recorded work, not attendance.';
  static const appVersion = 'App version',
      mode = 'Mode',
      demo = 'Demo',
      terms = 'Demo terms of use';
  static const privacy = 'Demo privacy information', reset = 'Reset demo data';
  static const resetTitle = 'Restore the original demo?',
      resetBody = 'This clears session changes and signs you out.';
  static const resetHint = 'Changes reset when the app restarts.';
  static const sampleHint =
      'All accounts and records are sample data.\nNo real SMS or API is connected.';
  static const emptyTasks = 'No tasks match these filters.',
      emptyPeople = 'No people found.';
  static const emptyActivity = 'No activity yet.',
      emptyReview = 'No tasks waiting for review.';
  static const saved = 'Changes saved.',
      assignedSuccess = 'Task assigned.',
      timeSaved = 'Work time saved.';
  static const running = 'Timer running',
      timerStopped = 'Timer stopped.',
      approved = 'Task approved.';
  static const accessDenied = 'You do not have access to this record.';
  static const notFound = 'This page or record could not be found.';
  static const offline =
      'The demo offline scenario is active. Turn it off in Settings to retry.';
  static const invalidPhone =
      'Enter a phone number from the demo account list.';
  static const invalidOtp = 'Enter the six-digit code 123456.';
  static const expiredOtp = 'The code has expired. Request a new code.';
  static const cooldown = 'Wait for the resend countdown.';
  static const authRequired = 'Please sign in again.';
  static const required = 'This field is required.';
  static const invalidTitle = 'Use a title between 3 and 100 characters.';
  static const invalidNote = 'Use a note between 5 and 500 characters.';
  static const invalidDescription =
      'Description must be at most 1,000 characters.';
  static const invalidDue = 'Choose today or a future due date.';
  static const invalidProgress = 'Progress must be between 0 and 100.';
  static const invalidTransition = 'This status change is not allowed.';
  static const reviewNeedsProgress = 'Set progress to 100% before submitting.';
  static const blockerRequired = 'Add a reason before marking work blocked.';
  static const invalidAssignee =
      'Choose an active employee in the permitted team.';
  static const readOnly = 'Completed tasks are read-only.';
  static const timerExists = 'Stop your running timer before starting another.';
  static const noOpenTimer = 'There is no running entry to stop.';
  static const invalidTime =
      'Use a past interval, start before end, at most 12 hours.';
  static const overlappingTime = 'This interval overlaps another work entry.';
  static const inactiveTask =
      'Time can only be logged to your Todo or In progress task.';
  static const activeAssignments =
      'Reassign or finish active tasks and stop work before changing access.';
  static const protectedAdmin =
      'The company Super Admin and designated team managers must stay active.';
  static const teamRequired = 'Choose a managed team for an Admin.';
  static const connectionFailure = 'Could not connect. Please try again.';
  static const unexpectedFailure = 'Something went wrong. Please try again.';
  static const comingBackend =
      'Real API mode needs an implemented server contract.';
  static const offlineScenario = 'Simulate offline reads',
      offlineHint = 'Use this to practise loading errors and retry.';
  static const allTeams = 'All teams',
      allRoles = 'All roles',
      noManager = 'Company leadership';
  static const previousWeek = 'Previous week',
      nextWeek = 'Next week',
      inactive = 'Inactive';
  static const companyTimezone = 'Asia/Kolkata · 8-hour target day';
  static const confirm = 'Confirm', selectDate = 'Select date';
  static String greeting(String name) => 'Hello, $name';
  static String activeCount(int count) => '$count active tasks';
  static String taskCount(int count) => '$count tasks';
  static String employeeCount(int count) => '$count employees';
  static String accountCount(int count) => '$count accounts';
  static String codeFor(String phone) => 'Enter the code for $phone';
  static String resendIn(int seconds) => 'Resend code in $seconds s';
  static String percent(int value) => '$value%';
  static String due(String date) => 'Due $date';
  static String hours(String value) => '$value hours';
  static String by(String name) => 'Assigned by $name';
  static String logged(String value) => '$value logged';
  static String progressActivity(String name, int value) =>
      '$name updated progress to $value%.';
  static String assignedActivity(String name) => 'Assigned to $name.';
  static String statusActivity(String status) => 'Status changed to $status.';
}
