import '../models/models.dart';
import '../models/settings_models.dart';

/// In-memory app state. Starts empty: fill these from your backend after login.
/// (Swap this for a repository / provider / riverpod layer when you wire the API.)
class AppData {
  static List<Event> events = [];
  static List<OwnedTicket> myTickets = [];
  static List<MerchItem> merch = [];
  static UserProfile? user;
  static VerificationApplication? verification;
  static List<Event> myEvents = [];
    static List<Event> savedEvents = [];
  static List<Event> archivedEvents = [];
  static List<PersonSummary> closeFriends = [];
  static List<PersonSummary> blocked = [];
  static List<PaymentCard> cards = [];
}
