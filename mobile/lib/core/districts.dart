/// All 33 districts of Telangana. The English name is what the API stores; Telugu and Hindi are for display.
const telanganaDistricts = <(String en, String te, String hi)>[
  ('Adilabad', 'ఆదిలాబాద్', 'आदिलाबाद'),
  ('Bhadradri Kothagudem', 'భద్రాద్రి కొత్తగూడెం', 'भद्राद्री कोत्तागुडेम'),
  ('Hanumakonda', 'హనుమకొండ', 'हनुमकोंडा'),
  ('Hyderabad', 'హైదరాబాద్', 'हैदराबाद'),
  ('Jagtial', 'జగిత్యాల', 'जगतियाल'),
  ('Jangaon', 'జనగామ', 'जनगांव'),
  ('Jayashankar Bhupalpally', 'జయశంకర్ భూపాలపల్లి', 'जयशंकर भूपालपल्ली'),
  ('Jogulamba Gadwal', 'జోగులాంబ గద్వాల', 'जोगुलांबा गद्वाल'),
  ('Kamareddy', 'కామారెడ్డి', 'कामारेड्डी'),
  ('Karimnagar', 'కరీంనగర్', 'करीमनगर'),
  ('Khammam', 'ఖమ్మం', 'खम्मम'),
  ('Kumuram Bheem Asifabad', 'కుమురం భీం ఆసిఫాబాద్', 'कुमुरम भीम आसिफाबाद'),
  ('Mahabubabad', 'మహబూబాబాద్', 'महबूबाबाद'),
  ('Mahabubnagar', 'మహబూబ్‌నగర్', 'महबूबनगर'),
  ('Mancherial', 'మంచిర్యాల', 'मंचेरियल'),
  ('Medak', 'మెదక్', 'मेदक'),
  ('Medchal-Malkajgiri', 'మేడ్చల్-మల్కాజ్‌గిరి', 'मेडचल-मलकाजगिरी'),
  ('Mulugu', 'ములుగు', 'मुलुगु'),
  ('Nagarkurnool', 'నాగర్‌కర్నూల్', 'नागरकुरनूल'),
  ('Nalgonda', 'నల్గొండ', 'नलगोंडा'),
  ('Narayanpet', 'నారాయణపేట', 'नारायणपेट'),
  ('Nirmal', 'నిర్మల్', 'निर्मल'),
  ('Nizamabad', 'నిజామాబాద్', 'निज़ामाबाद'),
  ('Peddapalli', 'పెద్దపల్లి', 'पेद्दापल्ली'),
  ('Rajanna Sircilla', 'రాజన్న సిరిసిల్ల', 'राजन्ना सिरसिल्ला'),
  ('Rangareddy', 'రంగారెడ్డి', 'रंगारेड्डी'),
  ('Sangareddy', 'సంగారెడ్డి', 'संगारेड्डी'),
  ('Siddipet', 'సిద్దిపేట', 'सिद्दीपेट'),
  ('Suryapet', 'సూర్యాపేట', 'सूर्यापेट'),
  ('Vikarabad', 'వికారాబాద్', 'विकाराबाद'),
  ('Wanaparthy', 'వనపర్తి', 'वनपर्ती'),
  ('Warangal', 'వరంగల్', 'वारंगल'),
  ('Yadadri Bhuvanagiri', 'యాదాద్రి భువనగిరి', 'यादाद्री भुवनगिरी'),
];

/// [en] (as stored) in the app language; a name not in the list is shown as stored.
String districtName(String en, String lang) {
  final d = telanganaDistricts.where((d) => d.$1 == en).firstOrNull;
  if (d == null) return en;
  return switch (lang) { 'te' => d.$2, 'hi' => d.$3, _ => d.$1 };
}
