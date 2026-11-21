/// Kindgerechter Grundwortschatz (1. Klasse Volksschule, Österreich).
///
/// Jeder Eintrag ist mit Bindestrichen in Silben getrennt (für die
/// Silbenbögen). Nomen werden groß geschrieben. Der Generator nimmt nur
/// Wörter, deren Buchstaben alle schon gelernt wurden – die Liste darf also
/// ruhig Wörter mit noch unbekannten Buchstaben enthalten.
library;

const woerter = [
  // kleine Wörter
  'am', 'im', 'um', 'so', 'es', 'er', 'sie', 'mir', 'als', 'aus', 'sei',
  'mal', 'al-so', 'al-le', 'lei-se', 'ro-sa', 'li-la', 'ist', 'und',
  'ein', 'da', 'wo', 'du', 'ich', 'mit', 'nein', 'ja', 'oh-ne',
  // Nomen mit A E I O U L S M R
  'Ei', 'Eis', 'Mus', 'Mai', 'Mais', 'Maus', 'Laus', 'Reis', 'Seil',
  'Meer', 'See', 'Aal', 'Moos', 'Leim', 'Maul', 'Lamm', 'Los',
  'O-ma', 'Ma-ma', 'La-ma', 'Li-mo', 'Ro-se', 'E-sel', 'Eu-le',
  'Rie-se', 'Rei-se', 'Mei-se', 'Ei-mer', 'Mau-er', 'Rol-le',
  'Rol-ler', 'Las-so', 'Ses-sel', 'Mur-mel', 'Ras-sel', 'Mu-mie',
  'So-lo', 'Si-lo', 'Su-mo', 'Ul-me', 'Er-le', 'Al-lee', 'O-a-se',
  'Li-lie', 'Ma-ler', 'Rum-mel', 'A-mei-se', 'Sa-la-mi', 'Ma-ril-le',
  'Ur-o-ma', 'Mu-se-um', 'Ma-le-rei',
  // weitere Buchstaben (für spätere Blätter)
  'O-pa', 'Pa-pa', 'Ha-se', 'Ho-se', 'Na-se', 'Na-me', 'Tor', 'Hut',
  'Ball', 'Baum', 'Bus', 'Bett', 'Hund', 'Haus', 'I-gel', 'Kind',
  'Nest', 'Ne-bel', 'Son-ne', 'Mond', 'Stern', 'Wal', 'Wolf', 'Fisch',
  'Frosch', 'Hand', 'Tisch', 'Nu-del', 'Ap-fel', 'Bir-ne', 'Ba-na-ne',
  'Au-to', 'To-ma-te', 'Tan-te', 'On-kel', 'Ro-bo-ter', 'Ti-ger',
  'Ra-be', 'Lö-we', 'Kä-se', 'Bär', 'Zug', 'Zahn', 'Kat-ze',
  'Vo-gel', 'Hun-de', 'Ta-sche', 'Tun-nel', 'Lam-pe', 'Ro-si-ne',
  'Me-lo-ne', 'Ei-sen-bahn', 'Na-del', 'Mo-tor', 'Ra-ke-te',
  'Ka-mel', 'Ki-wi', 'Wol-ke', 'Him-mel', 'Blu-me',
];

/// Wörter, die in Silbenreihen nicht zufällig entstehen sollen.
const silbenSperre = {'sau', 'rum', 'mist', 'arsch', 'kack', 'pipi', 'sex'};
