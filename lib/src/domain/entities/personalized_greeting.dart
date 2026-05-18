class PersonalizedGreeting {
  const PersonalizedGreeting({
    required this.salutation,
    required this.headline,
    required this.body,
  });

  final String salutation;
  final String headline;
  final String body;

  static const fallback = PersonalizedGreeting(
    salutation: 'Hey friend',
    headline: 'How are you feeling today?',
    body: 'Pick a mood and Selvator will bring the right words closer.',
  );
}
