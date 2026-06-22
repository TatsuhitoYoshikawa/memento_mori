#!/usr/bin/env python3
"""assets/life_table.json を生成するスクリプト。

UN World Population Prospects 2024 の R データパッケージ PPgp/wpp2024 が同梱する
1x1（各歳）死亡率 mx（mx1dt.rda）から、国別・男女別の完全生命表を計算し、
各歳の平均余命 e_x（2023年推計）を JSON にまとめる。未収録国向けに世界平均（WORLD）も収録。

依存: pip install pyreadr pycountry numpy pandas
使い方:
    # mx1dt.rda を取得（GitHub raw から）
    curl -o mx1dt.rda https://raw.githubusercontent.com/PPgp/wpp2024/main/data/mx1dt.rda
    python3 tool/build_life_table.py mx1dt.rda assets/life_table.json
"""
import json
import sys

import numpy as np
import pycountry
import pyreadr

YEAR = 2023
MAXAGE = 100  # 開区間（100歳以上）


def life_table_ex(mx: np.ndarray, sex: str) -> np.ndarray:
    """各歳死亡率 mx（ages 0..MAXAGE）から各歳の平均余命 e_x を計算する。

    Coale-Demeny West の a0 補正を用いる完全生命表。
    """
    n = len(mx)
    ax = np.full(n, 0.5)
    m0 = mx[0]
    if sex == "M":
        ax[0] = 0.045 + 2.684 * m0 if m0 < 0.107 else 0.330
    else:
        ax[0] = 0.053 + 2.800 * m0 if m0 < 0.107 else 0.350

    q = mx / (1.0 + (1.0 - ax) * mx)  # nx = 1
    q[-1] = 1.0  # 最終開区間
    lx = np.empty(n)
    lx[0] = 1e5
    for i in range(1, n):
        lx[i] = lx[i - 1] * (1.0 - q[i - 1])
    dx = np.empty(n)
    dx[:-1] = lx[:-1] - lx[1:]
    dx[-1] = lx[-1]
    Lx = np.empty(n)
    Lx[:-1] = lx[1:] + ax[:-1] * dx[:-1]
    Lx[-1] = lx[-1] / mx[-1] if mx[-1] > 0 else 0.0
    Tx = np.cumsum(Lx[::-1])[::-1]
    return Tx / lx


def main(rda_path: str, out_path: str) -> None:
    mx = pyreadr.read_r(rda_path)["mx1dt"]
    mx = mx[mx.year == YEAR]

    num2a2 = {
        int(c.numeric): c.alpha_2
        for c in pycountry.countries
        if getattr(c, "numeric", None)
    }

    out = {
        "source": (
            "UN World Population Prospects 2024 (PPgp/wpp2024), "
            f"complete life tables computed from 1x1 mx, year {YEAR}"
        ),
        "year": YEAR,
        "maxAge": MAXAGE,
        "fallbackCode": "WORLD",
        "countries": {},
    }

    for cc, g in mx.groupby("country_code"):
        g = g.sort_values("age")
        if len(g) != MAXAGE + 1:
            continue
        if cc == 900:
            key = "WORLD"
        elif cc in num2a2:
            key = num2a2[cc]
        else:
            continue  # 集計地域や ISO 非対応のロケーションは除外
        ex_m = life_table_ex(g.mxM.values, "M")
        ex_f = life_table_ex(g.mxF.values, "F")
        out["countries"][key] = {
            "male": {str(a): round(float(v), 2) for a, v in zip(g.age.values, ex_m)},
            "female": {str(a): round(float(v), 2) for a, v in zip(g.age.values, ex_f)},
        }

    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(out, f, ensure_ascii=False, separators=(",", ":"))
    print(f"wrote {len(out['countries'])} entries to {out_path}")


if __name__ == "__main__":
    rda = sys.argv[1] if len(sys.argv) > 1 else "mx1dt.rda"
    out = sys.argv[2] if len(sys.argv) > 2 else "assets/life_table.json"
    main(rda, out)
