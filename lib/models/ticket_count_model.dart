class TicketCount {
  final int tickets;
  final int reviews;
  final int invitations;

  TicketCount({
    required this.tickets,
    required this.reviews,
    required this.invitations,
  });

  factory TicketCount.fromJson(Map<String, dynamic> json) {
    return TicketCount(
      tickets: json['tickets'] as int? ?? 0,
      reviews: json['reviews'] as int? ?? 0,
      invitations: json['invitations'] as int? ?? 0,
    );
  }
}
