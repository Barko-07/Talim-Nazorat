class NamanganData {
  static const String defaultRegion = 'Namangan viloyati';

  // Namangan viloyatining barcha 14 ta ma'muriy hududi (Chortoq tumani asosiy)
  static const List<String> districts = [
    'Chortoq tumani',
    'Namangan shahri',
    'Davlatobod tumani',
    'Yangi Namangan tumani',
    'Chust tumani',
    'Kosonsoy tumani',
    'Mingbuloq tumani',
    'Namangan tumani',
    'Norin tumani',
    'Pop tumani',
    'To‘raqo‘rg‘on tumani',
    'Uychi tumani',
    'Uchqo‘rg‘on tumani',
    'Yangiqo‘rg‘on tumani',
  ];

  static const String defaultDistrict = 'Chortoq tumani';

  static const String customSchoolOption = 'Boshqa maktab (Qo‘lda yozish)';

  // Har bir tuman bo'yicha namunaviy va inklyuziv maktablar ro'yxati
  static const Map<String, List<String>> districtSchools = {
    // Chortoq tumanida 59 ta maktab (Statistika qo'mitasi, 2023). Serverdagi
    // ro'yxat bilan bir xil nomlar; server ro'yxati bo'lsa u ishlatiladi.
    'Chortoq tumani': [
      '1-sonli maktab',
      '2-sonli maktab',
      '3-sonli maktab',
      '4-sonli maktab',
      '5-sonli maktab',
      '6-sonli maktab',
      '7-sonli maktab',
      '8-sonli maktab',
      '9-sonli maktab',
      '10-sonli maktab',
      '11-sonli maktab',
      '12-sonli maktab',
      '13-sonli maktab',
      '14-sonli maktab',
      '15-sonli maktab',
      '16-sonli maktab',
      '17-sonli maktab',
      '18-sonli maktab',
      '19-sonli maktab',
      '20-sonli maktab',
      '21-sonli maktab',
      '22-sonli maktab',
      '23-sonli maktab',
      '24-sonli maktab',
      '25-sonli maktab',
      '26-sonli maktab',
      '27-sonli maktab',
      '28-sonli maktab',
      '29-sonli maktab',
      '30-sonli maktab',
      '31-sonli maktab',
      '32-sonli maktab',
      '33-sonli maktab',
      '34-sonli maktab',
      '35-sonli maktab',
      '36-sonli maktab',
      '37-sonli maktab',
      '38-sonli maktab',
      '39-sonli maktab',
      '40-sonli maktab',
      '41-sonli maktab',
      '42-sonli maktab',
      '43-sonli maktab',
      '44-sonli maktab',
      '45-sonli maktab',
      '46-sonli maktab',
      '47-sonli maktab',
      '48-sonli maktab',
      '49-sonli maktab',
      '50-sonli maktab',
      '51-sonli maktab',
      '52-sonli maktab',
      '53-sonli maktab',
      '54-sonli maktab',
      '55-sonli maktab',
      '56-sonli maktab',
      '57-sonli maktab',
      '58-sonli maktab',
      '59-sonli maktab',
    ],
    'Chust tumani': [
      '3-sonli umumiy o‘rta ta’lim maktabi',
      '9-sonli umumiy o‘rta ta’lim maktabi',
      '12-sonli inklyuziv maktab',
      '25-sonli ixtisoslashtirilgan maktab-internat',
      '38-sonli umumiy o‘rta ta’lim maktabi',
      '61-sonli umumiy o‘rta ta’lim maktabi',
      '74-sonli umumiy o‘rta ta’lim maktabi',
    ],
    'Kosonsoy tumani': [
      '2-sonli umumiy o‘rta ta’lim maktabi',
      '8-sonli umumiy o‘rta ta’lim maktabi',
      '19-sonli inklyuziv maktab',
      '31-sonli umumiy o‘rta ta’lim maktabi',
      '46-sonli umumiy o‘rta ta’lim maktabi',
      '57-sonli umumiy o‘rta ta’lim maktabi',
    ],
    'Mingbuloq tumani': [
      '4-sonli umumiy o‘rta ta’lim maktabi',
      '13-sonli umumiy o‘rta ta’lim maktabi',
      '20-sonli inklyuziv maktab',
      '35-sonli umumiy o‘rta ta’lim maktabi',
      '44-sonli umumiy o‘rta ta’lim maktabi',
    ],
    'Namangan tumani': [
      '6-sonli umumiy o‘rta ta’lim maktabi',
      '16-sonli umumiy o‘rta ta’lim maktabi',
      '27-sonli inklyuziv maktab',
      '42-sonli umumiy o‘rta ta’lim maktabi',
      '55-sonli umumiy o‘rta ta’lim maktabi',
    ],
    'Norin tumani': [
      '5-sonli umumiy o‘rta ta’lim maktabi',
      '18-sonli umumiy o‘rta ta’lim maktabi',
      '23-sonli inklyuziv maktab',
      '37-sonli umumiy o‘rta ta’lim maktabi',
      '49-sonli umumiy o‘rta ta’lim maktabi',
    ],
    'Pop tumani': [
      '1-sonli umumiy o‘rta ta’lim maktabi',
      '10-sonli umumiy o‘rta ta’lim maktabi',
      '21-sonli inklyuziv maktab',
      '45-sonli umumiy o‘rta ta’lim maktabi',
      '63-sonli umumiy o‘rta ta’lim maktabi',
    ],
    'To‘raqo‘rg‘on tumani': [
      '7-sonli umumiy o‘rta ta’lim maktabi',
      '14-sonli umumiy o‘rta ta’lim maktabi',
      '24-sonli inklyuziv maktab',
      '39-sonli ixtisoslashtirilgan maktab',
      '51-sonli umumiy o‘rta ta’lim maktabi',
    ],
    'Uychi tumani': [
      '3-sonli umumiy o‘rta ta’lim maktabi',
      '11-sonli umumiy o‘rta ta’lim maktabi',
      '29-sonli inklyuziv maktab',
      '44-sonli umumiy o‘rta ta’lim maktabi',
      '56-sonli umumiy o‘rta ta’lim maktabi',
    ],
    'Uchqo‘rg‘on tumani': [
      '2-sonli umumiy o‘rta ta’lim maktabi',
      '15-sonli umumiy o‘rta ta’lim maktabi',
      '32-sonli inklyuziv maktab',
      '48-sonli umumiy o‘rta ta’lim maktabi',
      '60-sonli umumiy o‘rta ta’lim maktabi',
    ],
    'Yangiqo‘rg‘on tumani': [
      '4-sonli umumiy o‘rta ta’lim maktabi',
      '17-sonli umumiy o‘rta ta’lim maktabi',
      '33-sonli inklyuziv maktab',
      '50-sonli umumiy o‘rta ta’lim maktabi',
      '62-sonli umumiy o‘rta ta’lim maktabi',
    ],
  };

  static List<String> getSchoolsForDistrict(String district) {
    return districtSchools[district] ??
        [
          '1-sonli umumiy o‘rta ta’lim maktabi',
          '14-sonli inklyuziv maktab',
          '25-sonli umumiy o‘rta ta’lim maktabi',
        ];
  }
}
