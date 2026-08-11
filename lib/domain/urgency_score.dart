/// Computes a single urgency score for a pending payment (loan installment
/// or card due date), combining how soon it's due with how much it costs.
///
/// The scoring intent, from most to least urgent:
///   1. Overdue items always outrank items that are not yet due.
///   2. Among items with the same due-date bucket, a larger amount is more
///      urgent than a smaller one.
///
/// Formula: `score = -daysUntilDue * 1000 + amount / 1000`.
///
/// The `-daysUntilDue * 1000` term dominates almost every comparison: each
/// day of difference is worth 1000 points, so two items due on different
/// days are essentially always ordered by date first. The `amount / 1000`
/// term only matters as a tiebreaker between items due on (or very near)
/// the same day, since realistic installment/balance amounts (thousands to
/// low millions of COP) translate into a handful to a few thousand points —
/// far less than a single day's 1000-point swing. Negative `daysUntilDue`
/// (overdue) flips the sign, pushing the score up sharply, so any overdue
/// item outranks any not-yet-due item regardless of amount.
///
/// Sort descending by this score to get most-urgent-first.
double urgencyScore({required int daysUntilDue, required double amount}) {
  return -daysUntilDue * 1000 + amount / 1000;
}
