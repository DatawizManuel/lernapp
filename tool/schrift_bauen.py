"""Baut die Lernapp-Schrift aus Andika (SIL, Open Font License 1.1).

Änderungen gegenüber Andika: kleines "l" mit Bogen unten (wie in der
österreichischen Volksschule), nur lateinische Zeichen, eigener Name
(Andika ist ein "Reserved Font Name" und darf verändert nicht so heißen).

    pip install fonttools
    python3 tool/schrift_bauen.py <Ordner mit Andika-Regular.ttf und Andika-Bold.ttf>

Andika: https://github.com/silnrsi/font-andika/releases (verwendet: 7.000)
"""

import sys
from pathlib import Path

from fontTools import subset
from fontTools.ttLib import TTFont

NAME = "Lernapp Schrift"
ZEICHEN = "U+0020-007E,U+00A0-00FF,U+0152-0153,U+2013-2014,U+2018-201E,U+2022,U+2026,U+20AC,U+2212"


def baue(quelle: Path, ziel: Path, stil: str) -> None:
    font = TTFont(quelle)
    for tabelle in font["cmap"].tables:
        if ord("l") in tabelle.cmap:
            tabelle.cmap[ord("l")] = "l.TailL"
    optionen = subset.Options()
    optionen.layout_features = ["*"]
    optionen.name_IDs = ["*"]
    sub = subset.Subsetter(optionen)
    sub.populate(unicodes=subset.parse_unicodes(ZEICHEN))
    sub.subset(font)
    namen = font["name"]
    voll = f"{NAME} {stil}"
    ps = f"{NAME.replace(' ', '')}-{stil}"
    for eintrag in list(namen.names):
        if eintrag.nameID in (1, 16):
            namen.setName(NAME, 1 if eintrag.nameID == 1 else 16, eintrag.platformID,
                          eintrag.platEncID, eintrag.langID)
        elif eintrag.nameID in (3, 4):
            namen.setName(voll, eintrag.nameID, eintrag.platformID, eintrag.platEncID,
                          eintrag.langID)
        elif eintrag.nameID == 6:
            namen.setName(ps, 6, eintrag.platformID, eintrag.platEncID, eintrag.langID)
    font.save(ziel)


if __name__ == "__main__":
    ordner = Path(sys.argv[1])
    ziel = Path(__file__).parent.parent / "assets" / "fonts"
    for stil in ("Regular", "Bold"):
        baue(ordner / f"Andika-{stil}.ttf", ziel / f"LernappSchrift-{stil}.ttf", stil)
