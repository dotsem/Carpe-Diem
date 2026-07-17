import 'package:flutter/material.dart';

class TagProfileItem {
  final String name;
  final IconData icon;

  const TagProfileItem({required this.name, required this.icon});
}

class TagProfile {
  final String name;
  final String description;
  final IconData icon;
  final List<TagProfileItem> tags;

  const TagProfile({
    required this.name,
    required this.description,
    required this.icon,
    required this.tags,
  });

  static const List<TagProfile> predefinedProfiles = [
    TagProfile(
      name: 'Work / Professional',
      description: 'For meetings, projects, admin tasks, and career development.',
      icon: Icons.business_center,
      tags: [
        TagProfileItem(name: 'meeting', icon: Icons.people),
        TagProfileItem(name: 'admin', icon: Icons.admin_panel_settings),
        TagProfileItem(name: 'project', icon: Icons.assignment),
        TagProfileItem(name: 'learning', icon: Icons.school),
        TagProfileItem(name: 'networking', icon: Icons.connect_without_contact),
        TagProfileItem(name: 'focus', icon: Icons.center_focus_strong),
        TagProfileItem(name: 'feedback', icon: Icons.feedback),
        TagProfileItem(name: 'planning', icon: Icons.next_plan),
        TagProfileItem(name: 'email', icon: Icons.email),
        TagProfileItem(name: 'urgent', icon: Icons.report_problem),
      ],
    ),
    TagProfile(
      name: 'Academic / Study',
      description: 'For tracking classes, lectures, exams, research, and homework.',
      icon: Icons.school,
      tags: [
        TagProfileItem(name: 'lecture', icon: Icons.co_present),
        TagProfileItem(name: 'homework', icon: Icons.menu_book),
        TagProfileItem(name: 'exam', icon: Icons.quiz),
        TagProfileItem(name: 'reading', icon: Icons.import_contacts),
        TagProfileItem(name: 'research', icon: Icons.science),
        TagProfileItem(name: 'revision', icon: Icons.history_edu),
        TagProfileItem(name: 'assignment', icon: Icons.assignment_turned_in),
        TagProfileItem(name: 'group-work', icon: Icons.groups),
        TagProfileItem(name: 'notes', icon: Icons.note_alt),
      ],
    ),
    TagProfile(
      name: 'Personal Life / Routine',
      description: 'For daily chores, home management, shopping, and family time.',
      icon: Icons.home,
      tags: [
        TagProfileItem(name: 'chore', icon: Icons.cleaning_services),
        TagProfileItem(name: 'grocery', icon: Icons.shopping_cart),
        TagProfileItem(name: 'finance', icon: Icons.monetization_on),
        TagProfileItem(name: 'errand', icon: Icons.directions_run),
        TagProfileItem(name: 'home', icon: Icons.home),
        TagProfileItem(name: 'family', icon: Icons.favorite),
        TagProfileItem(name: 'maintenance', icon: Icons.build),
        TagProfileItem(name: 'shopping', icon: Icons.shopping_bag),
      ],
    ),
    TagProfile(
      name: 'Health / Wellness',
      description: 'For tracking workouts, diet, sleep, and self-care routines.',
      icon: Icons.favorite_border,
      tags: [
        TagProfileItem(name: 'workout', icon: Icons.fitness_center),
        TagProfileItem(name: 'meditation', icon: Icons.self_improvement),
        TagProfileItem(name: 'self-care', icon: Icons.spa),
        TagProfileItem(name: 'doctor', icon: Icons.local_hospital),
        TagProfileItem(name: 'sleep', icon: Icons.bedtime),
        TagProfileItem(name: 'meal-prep', icon: Icons.soup_kitchen),
        TagProfileItem(name: 'hygiene', icon: Icons.clean_hands),
        TagProfileItem(name: 'mental-health', icon: Icons.psychology),
        TagProfileItem(name: 'nature', icon: Icons.forest),
      ],
    ),
    TagProfile(
      name: 'Hobbies / Leisure',
      description: 'For creative writing, arts, gaming, music, and movie logging.',
      icon: Icons.palette,
      tags: [
        TagProfileItem(name: 'hobby', icon: Icons.sports_esports),
        TagProfileItem(name: 'creative', icon: Icons.palette),
        TagProfileItem(name: 'gaming', icon: Icons.videogame_asset),
        TagProfileItem(name: 'reading', icon: Icons.book),
        TagProfileItem(name: 'music', icon: Icons.music_note),
        TagProfileItem(name: 'diy', icon: Icons.handyman),
        TagProfileItem(name: 'social', icon: Icons.chat),
        TagProfileItem(name: 'movie', icon: Icons.movie),
        TagProfileItem(name: 'sport', icon: Icons.sports_soccer),
      ],
    ),
    TagProfile(
      name: 'Productivity (GTD)',
      description: 'To organize tasks by priority, context, and energy levels.',
      icon: Icons.bolt,
      tags: [
        TagProfileItem(name: 'quick-win', icon: Icons.bolt),
        TagProfileItem(name: 'deep-work', icon: Icons.psychology_alt),
        TagProfileItem(name: 'low-energy', icon: Icons.battery_2_bar),
        TagProfileItem(name: 'high-priority', icon: Icons.priority_high),
        TagProfileItem(name: 'waiting', icon: Icons.hourglass_empty),
        TagProfileItem(name: 'someday', icon: Icons.explore),
        TagProfileItem(name: 'delegate', icon: Icons.assignment_ind),
      ],
    ),
    TagProfile(
      name: 'Programming / Software Dev',
      description: 'For issue tracking, docs, testing, and dev pipelines.',
      icon: Icons.code,
      tags: [
        TagProfileItem(name: 'bug', icon: Icons.bug_report),
        TagProfileItem(name: 'feature', icon: Icons.add_box),
        TagProfileItem(name: 'chore', icon: Icons.build),
        TagProfileItem(name: 'docs', icon: Icons.description),
        TagProfileItem(name: 'refactor', icon: Icons.autorenew),
        TagProfileItem(name: 'review', icon: Icons.rate_review),
        TagProfileItem(name: 'test', icon: Icons.science),
        TagProfileItem(name: 'deploy', icon: Icons.rocket_launch),
        TagProfileItem(name: 'research', icon: Icons.search),
      ],
    ),
  ];
}
