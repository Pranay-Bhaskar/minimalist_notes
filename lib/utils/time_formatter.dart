String getRelativeTime(int timestamp) {
  final now = DateTime.now();
  final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
  final difference = now.difference(date);

  if (difference.inDays > 1) return '${difference.inDays} days ago';
  if (difference.inDays == 1) return 'yesterday';
  if (difference.inHours > 0) return '${difference.inHours}h ago';
  if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
  return 'just now';
}