/// Deterministic, offline merchant→category classifier. Used by the Add-Expense
/// flow (auto-suggest), the SMS parser, and as the AI categorization fallback
/// when no Groq key is configured. Keyword order matters: first match wins.
class RuleCategorizer {
  RuleCategorizer._();

  static const Map<String, List<String>> _rules = {
    'Food': ['swiggy', 'zomato', 'eatfit', 'faasos', 'box8', 'food', 'dominos', 'mcdonald', 'kfc', 'burger', 'pizza'],
    'Restaurants': ['restaurant', 'truffles', 'barbeque', 'cafe ', 'dining', 'bistro', 'biryani'],
    'Coffee': ['starbucks', 'coffee', 'chai', 'blue tokai', 'third wave', 'ccd'],
    'Groceries': ['bigbasket', 'blinkit', 'zepto', 'grofers', 'dmart', 'instamart', 'grocery', 'supermarket', 'reliance fresh'],
    'Shopping': ['amazon', 'flipkart', 'myntra', 'ajio', 'meesho', 'nykaa', 'tatacliq', 'shop'],
    'Clothing': ['zara', 'h&m', 'uniqlo', 'levis', 'westside', 'lifestyle', 'max fashion'],
    'Electronics': ['croma', 'reliance digital', 'apple', 'samsung', 'boat', 'vijay sales'],
    'Taxi': ['uber', 'ola', 'rapido', 'meru', 'taxi'],
    'Fuel': ['indian oil', 'bharat petroleum', 'hp ', 'hindustan petroleum', 'shell', 'fuel', 'petrol'],
    'Transport': ['metro', 'irctc', 'redbus', 'bmtc', 'bus', 'railway', 'namma'],
    'Travel': ['makemytrip', 'goibibo', 'cleartrip', 'ixigo', 'yatra', 'airbnb'],
    'Flights': ['indigo', 'vistara', 'air india', 'spicejet', 'akasa'],
    'Hotels': ['oyo', 'hotel', 'marriott', 'taj ', 'lemon tree', 'fabhotel'],
    'OTT': ['netflix', 'spotify', 'hotstar', 'prime video', 'sony liv', 'zee5', 'youtube premium'],
    'Movies': ['bookmyshow', 'pvr', 'inox', 'cinepolis', 'movie'],
    'Gaming': ['steam', 'playstation', 'xbox', 'epic games', 'nintendo'],
    'Pharmacy': ['apollo', 'pharmeasy', 'netmeds', '1mg', 'medplus', 'pharmacy', 'chemist'],
    'Healthcare': ['hospital', 'clinic', 'practo', 'diagnostic', 'lab', 'doctor'],
    'Insurance': ['insurance', 'policybazaar', 'lic ', 'premium', 'hdfc life'],
    'Education': ['udemy', 'coursera', 'unacademy', 'byju', 'school', 'college', 'tuition'],
    'Rent': ['rent', 'landlord', 'lease'],
    'Electricity': ['electricity', 'bescom', 'tata power', 'adani electric', 'msedcl'],
    'Water': ['water', 'jal board', 'bwssb'],
    'Gas': ['gas', 'indane', 'hp gas', 'bharat gas'],
    'Internet': ['airtel fiber', 'jiofiber', 'act ', 'broadband', 'hathway', 'internet'],
    'Mobile': ['jio recharge', 'airtel recharge', 'vi recharge', 'recharge', 'prepaid'],
    'EMI': ['emi', 'instalment', 'installment'],
    'Loans': ['loan', 'bajaj finserv', 'creditbee'],
    'Mutual Funds': ['groww', 'mutual fund', 'kuvera', 'coin'],
    'SIP': ['sip', 'systematic'],
    'Stocks': ['zerodha', 'upstox', 'angel one', 'stock'],
    'Crypto': ['wazirx', 'coindcx', 'binance', 'crypto'],
    'Fitness': ['cult.fit', 'cultfit', 'gym', 'fitness', 'decathlon'],
    'Beauty': ['salon', 'spa', 'lakme', 'beauty'],
    'Subscription': ['subscription', 'membership', 'patreon', 'notion', 'figma'],
    'Charity': ['donation', 'ngo', 'charity', 'milaap'],
    'Salary': ['salary', 'payroll', 'sal cr', 'wages'],
    'Cashback': ['cashback', 'reward', 'cred'],
    'Refund': ['refund', 'reversal'],
  };

  /// Returns a best-guess category name for the given merchant/description.
  static String categorize(String text, {bool isIncome = false}) {
    final t = text.toLowerCase();
    if (isIncome) {
      for (final cat in ['Salary', 'Cashback', 'Refund']) {
        if (_rules[cat]!.any(t.contains)) return cat;
      }
      return 'Salary';
    }
    for (final entry in _rules.entries) {
      if (entry.value.any(t.contains)) return entry.key;
    }
    return 'Miscellaneous';
  }
}
