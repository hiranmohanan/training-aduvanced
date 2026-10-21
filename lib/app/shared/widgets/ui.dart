import 'package:flutter/material.dart';
import '../../app_constants/app_text.dart';
import '../../models/app_user.dart';
import '../../models/enums.dart';
import '../../models/task.dart';
import '../../services/clock/clock_service.dart';
import '../../theme/app_theme.dart';

class Gap extends StatelessWidget {
  const Gap([this.height = 20, Key? key]) : super(key: key);
  final double height;
  @override
  Widget build(BuildContext context) => SizedBox(height: height);
}

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.color,
  });
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final Color? color;
  @override
  Widget build(BuildContext context) => Card(
    color: color,
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(padding: padding, child: child),
    ),
  );
}

class PageColumn extends StatelessWidget {
  const PageColumn({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    ),
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.action, this.onTap});
  final String text;
  final String? action;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          text,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      if (action != null) TextButton(onPressed: onTap, child: Text(action!)),
    ],
  );
}

class PersonAvatar extends StatelessWidget {
  const PersonAvatar(this.name, {super.key, this.radius = 22});
  final String name;
  final double radius;
  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: radius,
    backgroundColor: AppColors.pale,
    child: Text(
      name
          .split(' ')
          .where((s) => s.isNotEmpty)
          .take(2)
          .map((s) => s[0])
          .join(),
      style: TextStyle(
        fontSize: radius * .7,
        fontWeight: FontWeight.w700,
        color: AppColors.blue,
      ),
    ),
  );
}

class PersonTile extends StatelessWidget {
  const PersonTile(
    this.user, {
    super.key,
    this.subtitle,
    this.onTap,
    this.trailing,
  });
  final AppUser user;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => AppCard(
    onTap: onTap,
    child: Row(
      children: [
        PersonAvatar(user.name),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.name,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const Gap(4),
              Text(
                subtitle ?? user.designation,
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ],
          ),
        ),
        if (trailing != null)
          trailing!
        else if (onTap != null)
          const Icon(Icons.chevron_right, color: AppColors.muted),
      ],
    ),
  );
}

class StatCard extends StatelessWidget {
  const StatCard(
    this.label,
    this.value, {
    super.key,
    this.caption,
    this.color = AppColors.blue,
  });
  final String label, value;
  final String? caption;
  final Color color;
  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.muted),
        ),
        const Gap(8),
        Text(
          value,
          style: TextStyle(
            fontSize: 29,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        if (caption != null) ...[
          const Gap(5),
          Text(
            caption!,
            style: const TextStyle(fontSize: 11, color: AppColors.muted),
          ),
        ],
      ],
    ),
  );
}

class StatGrid extends StatelessWidget {
  const StatGrid({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => Wrap(
      spacing: 14,
      runSpacing: 14,
      children: children
          .map((w) => SizedBox(width: (box.maxWidth - 14) / 2, child: w))
          .toList(),
    ),
  );
}

Color statusColor(TaskStatus status) => switch (status) {
  TaskStatus.todo => AppColors.muted,
  TaskStatus.inProgress => AppColors.blue,
  TaskStatus.blocked => AppColors.amber,
  TaskStatus.inReview => AppColors.purple,
  TaskStatus.done => AppColors.green,
};

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});
  final TaskStatus status;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: statusColor(status).withValues(alpha: .09),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      status.label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: statusColor(status),
      ),
    ),
  );
}

class TaskCard extends StatelessWidget {
  const TaskCard(this.task, {super.key, required this.onTap, this.assignee});
  final Task task;
  final VoidCallback onTap;
  final String? assignee;
  @override
  Widget build(BuildContext context) => AppCard(
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                task.id,
                style: const TextStyle(fontSize: 11, color: AppColors.muted),
              ),
            ),
            StatusChip(task.status),
          ],
        ),
        const Gap(12),
        Text(
          task.title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        const Gap(8),
        Text(
          assignee ??
              '${AppText.due(ClockService.shortDate(task.dueAt))} · ${task.priority.label}',
          style: const TextStyle(fontSize: 12, color: AppColors.muted),
        ),
        const Gap(14),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: LinearProgressIndicator(
                  value: task.progress / 100,
                  minHeight: 6,
                  backgroundColor: AppColors.line,
                ),
              ),
            ),
            const SizedBox(width: 20),
            Text(
              AppText.percent(task.progress),
              style: const TextStyle(fontSize: 11, color: AppColors.muted),
            ),
          ],
        ),
      ],
    ),
  );
}

class MessageCard extends StatelessWidget {
  const MessageCard(
    this.message, {
    super.key,
    this.error = false,
    this.onRetry,
  });
  final String message;
  final bool error;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      children: [
        Icon(
          error ? Icons.info_outline : Icons.inbox_outlined,
          color: AppColors.muted,
        ),
        const Gap(10),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: error ? AppColors.red : AppColors.muted),
        ),
        if (onRetry != null) ...[
          const Gap(10),
          TextButton(onPressed: onRetry, child: const Text(AppText.retry)),
        ],
      ],
    ),
  );
}

class DetailRow extends StatelessWidget {
  const DetailRow(this.label, this.value, {super.key});
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}
