"""Derive the killerPals palettes from the standardised Queen album covers.

Pipeline, per album:

1.  Quantise the cover in CIELAB with k-means to get candidate colours,
    weighted by how much of the cover they occupy.
2.  Qualitative palette - greedily pick the most separable candidates, then
    refine each swatch inside a bounded neighbourhood of its seed so that the
    worst-case pairwise CIEDE2000 across normal, deuteranopic, protanopic and
    tritanopic vision is maximised, subject to WCAG contrast and lightness
    constraints.
3.  Sequential palette - a perceptually near-uniform, monotone-lightness LCh
    ramp on the album's *distinctive* hue: the hue it has more of than the
    catalogue average, assigned so no two albums share a ramp.
4.  Diverging palette - two arms meeting at a light neutral, with a symmetric
    lightness profile, on a hue pair that stays separable under CVD simulation
    and is not reused by another album.

Outputs `data-raw/palettes-generated.R` (copied to `R/` by `make palettes`) and
`data-raw/palettes.json`, plus a QA report on stderr.

Run with:  python3 data-raw/build_palettes.py
"""

from __future__ import annotations

import json
import os
import sys

import numpy as np
from PIL import Image
from sklearn.cluster import KMeans

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from colorsci import (  # noqa: E402
    CVD_TYPES,
    BLACK,
    WHITE,
    ciede2000,
    contrast_ratio,
    cvd_min_distance,
    hex_to_rgb,
    lab_to_rgb,
    rgb_to_hex,
    rgb_to_lab,
    simulate_cvd,
    swatch_contrast,
)

HERE = os.path.dirname(os.path.abspath(__file__))
COVERS = os.path.join(HERE, "covers")
RNG = np.random.default_rng(1975)  # A Night at the Opera

# ---------------------------------------------------------------- album table
# key, palette name, album title, year, one-line palette blurb
ALBUMS = [
    ("queen", "regina", "Queen", 1973,
     "Smoke, spotlight and stage-purple from the 1973 debut."),
    ("queen_ii", "mirror_queen", "Queen II", 1974,
     "The mirrored Mick Rock portrait: side White against side Black."),
    ("sheer_heart_attack", "heart_attack", "Sheer Heart Attack", 1974,
     "Oiled, exhausted and lit in sickly green - the 1974 pile-up."),
    ("night_at_the_opera", "opera_night", "A Night at the Opera", 1975,
     "Heraldic crest colours: cream, gilt and deep operatic red."),
    ("day_at_the_races", "race_day", "A Day at the Races", 1976,
     "The crest again, inverted - black lacquer and silver."),
    ("news_of_the_world", "robot_news", "News of the World", 1977,
     "Frank Kelly Freas's robot: pulp-magazine blues and steel."),
    ("jazz", "all_that_jazz", "Jazz", 1978,
     "Berlin Wall stencil geometry in flat, graphic primaries."),
    ("the_game", "game_on", "The Game", 1980,
     "Chrome, leather and cool monochrome with a flash of colour."),
    ("flash_gordon", "flash", "Flash Gordon", 1980,
     "Ah-ah! Saviour of the universe: comic-strip red, gold and void."),
    ("hot_space", "hot_space", "Hot Space", 1982,
     "Four flat pop-art blocks - the most graphic cover they made."),
    ("the_works", "the_works", "The Works", 1984,
     "George Hurrell's Hollywood monochrome, warmed by sepia light."),
    ("a_kind_of_magic", "kind_of_magic", "A Kind of Magic", 1986,
     "Roger Chiasson's cartoon night sky: neon over midnight blue."),
    ("the_miracle", "miracle", "The Miracle", 1989,
     "Four faces morphed into one, in cold studio light."),
    ("innuendo", "innuendo", "Innuendo", 1991,
     "Grandville's Victorian engraving, hand-tinted and ornate."),
    ("made_in_heaven", "heavenly", "Made in Heaven", 1995,
     "Montreux at dusk: lake blue, alpine grey and the last light."),
]

N_QUAL = 8          # colours in each qualitative palette
N_SEQ = 7           # anchor stops in each sequential palette
N_DIV = 11          # anchor stops in each diverging palette (odd -> true midpoint)

# --- accessibility targets ---------------------------------------------------
MIN_CVD_DE = 15.0   # worst-case pairwise CIEDE2000 under any simulated vision
L_RANGE = (28.0, 84.0)   # keeps swatches legible on white *and* dark panels
MIN_CONTRAST = 2.6  # vs. whichever of white/black gives more contrast


# ------------------------------------------------------------------ LCh utils

def lab_to_lch(lab: np.ndarray) -> np.ndarray:
    L, a, b = lab[..., 0], lab[..., 1], lab[..., 2]
    return np.stack([L, np.hypot(a, b), np.degrees(np.arctan2(b, a)) % 360], -1)


def lch_to_lab(lch: np.ndarray) -> np.ndarray:
    L, C, h = lch[..., 0], lch[..., 1], lch[..., 2]
    r = np.radians(h)
    return np.stack([L, C * np.cos(r), C * np.sin(r)], -1)


def in_gamut(lab: np.ndarray, tol: float = 1.2) -> bool:
    """True if `lab` survives a round trip through clipped sRGB."""
    back = rgb_to_lab(lab_to_rgb(lab))
    return float(ciede2000(lab, back)) < tol


def fit_gamut(lch: np.ndarray, tol: float = 1.2) -> np.ndarray:
    """Reduce chroma until the LCh colour is representable in sRGB."""
    lch = lch.copy()
    for _ in range(60):
        if in_gamut(lch_to_lab(lch), tol):
            break
        lch[..., 1] *= 0.96
    return lch


# ------------------------------------------------------- candidate extraction

def extract_candidates(path: str, k: int = 28) -> tuple[np.ndarray, np.ndarray]:
    """k-means the cover in Lab. Returns (lab centres, area weights)."""
    im = Image.open(path).convert("RGB").resize((200, 200), Image.LANCZOS)
    rgb = np.asarray(im, dtype=float).reshape(-1, 3) / 255.0
    lab = rgb_to_lab(rgb)
    km = KMeans(n_clusters=k, n_init=8, random_state=42).fit(lab)
    counts = np.bincount(km.labels_, minlength=k).astype(float)
    return km.cluster_centers_, counts / counts.sum()


def salience(lab: np.ndarray, weight: np.ndarray) -> np.ndarray:
    """Rank candidates by area *and* colourfulness, so ink beats background."""
    chroma = lab_to_lch(lab)[..., 1]
    return np.sqrt(weight) * (chroma + 8.0)


# --------------------------------------------------- qualitative optimisation

def _cvd_labs(rgb: np.ndarray) -> list[np.ndarray]:
    return [rgb_to_lab(simulate_cvd(rgb, k)) for k in CVD_TYPES]


def _min_pairwise(rgb: np.ndarray) -> float:
    worst = np.inf
    for lab in _cvd_labs(rgb):
        d = ciede2000(lab[:, None, :], lab[None, :, :])
        np.fill_diagonal(d, np.inf)
        worst = min(worst, float(d.min()))
    return worst


def _score(rgb: np.ndarray) -> float:
    """Objective: worst-case separation, penalised for contrast/lightness misses."""
    s = _min_pairwise(rgb)
    best = np.maximum(contrast_ratio(rgb, WHITE), contrast_ratio(rgb, BLACK))
    s -= 25.0 * float(np.clip(MIN_CONTRAST - best, 0, None).sum())
    L = rgb_to_lab(rgb)[:, 0]
    s -= 2.0 * float(np.clip(L_RANGE[0] - L, 0, None).sum())
    s -= 2.0 * float(np.clip(L - L_RANGE[1], 0, None).sum())
    return s


def seed_qualitative(lab: np.ndarray, weight: np.ndarray, n: int) -> np.ndarray:
    """Greedy max-min pick over candidates, biased towards salient colours."""
    sal = salience(lab, weight)
    # Pull candidates into the usable lightness band before comparing them.
    lch = lab_to_lch(lab).copy()
    lch[:, 0] = np.clip(lch[:, 0], L_RANGE[0] + 4, L_RANGE[1] - 4)
    lch[:, 1] = np.maximum(lch[:, 1], 12.0)
    cand = lch_to_lab(np.array([fit_gamut(c) for c in lch]))

    chosen = [int(np.argmax(sal))]
    while len(chosen) < n:
        d = ciede2000(cand[:, None, :], cand[None, chosen, :]).min(axis=1)
        d[chosen] = -np.inf
        chosen.append(int(np.argmax(d + 0.12 * sal)))
    return cand[chosen]


def refine_qualitative(seed_lab: np.ndarray, max_drift: float = 26.0,
                       iters: int = 4000) -> np.ndarray:
    """Nudge each swatch inside a bounded neighbourhood of its seed.

    Bounding the drift keeps the palette recognisably tied to the album art;
    the objective drives it towards colour-vision-deficiency separability.
    """
    cur = lab_to_lch(seed_lab).copy()
    cur_rgb = lab_to_rgb(lch_to_lab(cur))
    best, best_score = cur.copy(), _score(cur_rgb)
    n = len(cur)

    for it in range(iters):
        temp = 1.0 - it / iters
        i = RNG.integers(n)
        trial = cur.copy()
        trial[i, 0] += RNG.normal(0, 7 * temp + 1.5)
        trial[i, 1] += RNG.normal(0, 9 * temp + 2.0)
        trial[i, 2] += RNG.normal(0, 22 * temp + 4.0)
        trial[i, 0] = np.clip(trial[i, 0], *L_RANGE)
        trial[i, 1] = np.clip(trial[i, 1], 10.0, 128.0)
        trial[i, 2] %= 360.0
        trial[i] = fit_gamut(trial[i])

        trial_lab = lch_to_lab(trial)
        if float(ciede2000(trial_lab[i], seed_lab[i])) > max_drift:
            continue

        sc = _score(lab_to_rgb(trial_lab))
        if sc > best_score:
            best, best_score, cur = trial.copy(), sc, trial
        elif sc > _score(lab_to_rgb(lch_to_lab(cur))) - 1.5 * temp:
            cur = trial

    return lch_to_lab(best)


def order_qualitative(labs: np.ndarray) -> np.ndarray:
    """Order so consecutive swatches contrast strongly (2-3 series plots first)."""
    rgb = lab_to_rgb(labs)
    cvd = _cvd_labs(rgb)

    def sep(i: int, j: int) -> float:
        return min(float(ciede2000(l[i], l[j])) for l in cvd)

    remaining = set(range(len(labs)))
    start = int(np.argmax(np.abs(labs[:, 1]) + np.abs(labs[:, 2])))  # most chromatic
    order = [start]
    remaining.discard(start)
    while remaining:
        nxt = max(remaining, key=lambda j: min(sep(j, i) for i in order[-2:]))
        order.append(nxt)
        remaining.discard(nxt)
    return labs[order]


# ------------------------------------------------------- sequential/diverging

N_HUE_BINS = 36


def hue_histogram(lab: np.ndarray, weight: np.ndarray) -> np.ndarray:
    """Chroma-weighted hue histogram of a cover, normalised to sum 1."""
    lch = lab_to_lch(lab)
    hist = np.zeros(N_HUE_BINS)
    for (L, C, h), w in zip(lch, weight):
        if C < 8:
            continue  # near-neutral pixels carry no hue information
        hist[int(h / (360 / N_HUE_BINS)) % N_HUE_BINS] += w * C
    # Smooth so neighbouring bins reinforce rather than compete.
    k = np.array([0.25, 0.5, 1.0, 0.5, 0.25])
    hist = np.convolve(np.r_[hist[-2:], hist, hist[:2]], k, mode="same")[2:-2]
    total = hist.sum()
    return hist / total if total > 0 else np.ones(N_HUE_BINS) / N_HUE_BINS


def distinctive_hues(hist: np.ndarray, background: np.ndarray) -> list[float]:
    """Hues this cover has *more* of than the catalogue as a whole.

    Plain "most dominant hue" makes almost every ramp orange, because so many
    of the covers are sepia or warm-lit.  Dividing by the catalogue-wide hue
    profile (a TF-IDF style lift) surfaces what is characteristic of each
    album instead, so the fifteen sequential ramps stay distinguishable.
    """
    lift = (hist + 1e-4) / (background + 1e-4)
    order = np.argsort(-lift * (hist > hist.max() * 0.08))
    step = 360 / N_HUE_BINS
    return [(int(i) + 0.5) * step for i in order]


MIN_RAMP_HUE_GAP = 22.0  # degrees between any two albums' sequential ramps


def assign_ramp_hues(prefs: dict[str, list[float]],
                     strength: dict[str, float]) -> dict[str, float]:
    """Give every album its own sequential-ramp hue.

    Left to themselves, several albums pick the same hue (a lot of these covers
    are warm-lit), which would ship near-identical ramps.  Albums with the
    strongest hue signal claim their preferred hue first; the rest fall through
    to their next preference that is at least `MIN_RAMP_HUE_GAP` away.
    """
    taken: list[float] = []
    out: dict[str, float] = {}
    for name in sorted(prefs, key=lambda k: -strength[k]):
        for h in prefs[name]:
            if all(abs(((h - t + 180) % 360) - 180) >= MIN_RAMP_HUE_GAP for t in taken):
                out[name] = h
                taken.append(h)
                break
        else:  # every preference clashed - keep the favourite anyway
            out[name] = prefs[name][0]
    return out


def build_sequential(lab: np.ndarray, weight: np.ndarray, n: int,
                     hues: list[float], primary: float) -> list[str]:
    """Monotone-lightness multi-hue ramp anchored on the album's key hue."""
    h_dark = primary
    # Second hue gives the ramp a subtle viridis-like twist; cap the swing so
    # the result still reads as one colour family.
    h_light = h_dark
    for h in hues[1:]:
        delta = ((h - h_dark + 180) % 360) - 180
        if abs(delta) > 12:
            h_light = h_dark + float(np.clip(delta, -70, 70))
            break

    t = np.linspace(0.0, 1.0, n)
    L = 96.0 - 74.0 * t                          # light -> dark, strictly monotone
    C = 8.0 + 62.0 * np.sin(np.pi * (0.18 + 0.62 * t))
    H = h_light + (h_dark - h_light) * t
    ramp = np.array([fit_gamut(np.array([l, c, h])) for l, c, h in zip(L, C, H)])
    return [rgb_to_hex(lab_to_rgb(lch_to_lab(c))) for c in ramp]


# Measured at the geometry the arm *endpoints* actually use (see DIV_PROBE
# below), worst-case CIEDE2000 between two hues tops out near 48 and only ~5% of
# pairs clear 41, so the bar for "obviously different under every simulated
# vision type" sits at 30.
MIN_DIV_ARM_DE = 30.0

# The lightness/chroma of the darkest stop of each arm, i.e. `f = 1` in the ramp
# built below. Candidate hue pairs must be separable *here*, not at some rosier
# mid-lightness: CIEDE2000 compresses differences in dark, saturated colours, so
# probing at mid lightness overstates how distinguishable the endpoints are.
DIV_PROBE = (34.0, 72.0)


def _pairs_clash(a: tuple[float, float], b: tuple[float, float],
                 tol: float = 20.0) -> bool:
    """True if two hue pairs would render as the same diverging scale."""
    def near(x: float, y: float) -> bool:
        return abs(((x - y + 180) % 360) - 180) < tol
    return (near(a[0], b[0]) and near(a[1], b[1])) or \
           (near(a[0], b[1]) and near(a[1], b[0]))


def build_diverging(n: int, hues: list[float], primary: float,
                    used: list[tuple[float, float]] | None = None) -> list[str]:
    """Two album hues, forced far enough apart to read as a diverging scale.

    The first arm is pinned to the album's assigned primary hue so the diverging
    and sequential palettes belong to the same family; the second is the most
    distinctive remaining hue that stays separable from it under every simulated
    colour vision type *and* does not reproduce a pair already used by another
    album (two albums can otherwise land on the same pair from opposite ends).
    """
    used = [] if used is None else used
    # Distinctive album hues first; a coarse sweep of the whole wheel follows as
    # lower-priority fallback, so a separable *and* unused partner always exists
    # even for covers with only one or two strong hues.
    wheel = [float(h) for h in range(0, 360, 15)]
    cands = [primary] + [h for h in list(hues) + wheel
                         if abs(((h - primary + 180) % 360) - 180) > 20]
    probe = np.array([lch_to_lab(fit_gamut(np.array([DIV_PROBE[0], DIV_PROBE[1], h])))
                      for h in cands])
    cvd = _cvd_labs(lab_to_rgb(probe))

    def sep(i: int, j: int) -> float:
        return min(float(ciede2000(l[i], l[j])) for l in cvd)

    def unused(j: int) -> bool:
        return not any(_pairs_clash((cands[0], cands[j]), p) for p in used)

    # Separability is the accessibility promise; pair uniqueness is only
    # cosmetic.  So: prefer the most distinctive hue that is both separable and
    # unused, then fall back to the *most separable* hue even if another album
    # already uses that pair -- never to an unused-but-indistinguishable one.
    ok = [j for j in range(1, len(cands)) if sep(0, j) >= MIN_DIV_ARM_DE]
    by_sep = sorted(range(1, len(cands)), key=lambda j: -sep(0, j))
    partner = (
        next((j for j in ok if unused(j)), None)
        or (max(ok, key=lambda j: sep(0, j)) if ok else by_sep[0])
    )

    # Warmer hue on the left arm, so the ramp reads low -> high conventionally.
    h_lo, h_hi = cands[0], cands[partner]
    if not (0 <= ((h_lo - 30) % 360) <= 150):
        h_lo, h_hi = h_hi, h_lo
    used.append((h_lo, h_hi))

    half = n // 2
    stops = []
    for arm, hue in ((-1, h_lo), (1, h_hi)):
        for s in range(half, 0, -1):
            f = s / half
            L = 96.0 - 62.0 * f
            C = 6.0 + 66.0 * f**0.85
            stops.append((arm * f, fit_gamut(np.array([L, C, hue]))))
    stops.append((0.0, fit_gamut(np.array([96.5, 3.0, (h_lo + h_hi) / 2]))))
    stops.sort(key=lambda p: p[0])
    return [rgb_to_hex(lab_to_rgb(lch_to_lab(c))) for _, c in stops]


# ----------------------------------------------------------------------- main

def main() -> None:
    palettes: dict[str, dict] = {}
    qual_pool: list[tuple[str, str]] = []
    report: list[str] = []

    # Pass 1: quantise every cover and build the catalogue-wide hue profile that
    # `distinctive_hues()` divides through.
    print("quantising covers...", file=sys.stderr)
    covers = {}
    for key, *_ in ALBUMS:
        lab, weight = extract_candidates(os.path.join(COVERS, f"{key}.png"))
        covers[key] = (lab, weight, hue_histogram(lab, weight))
    background = np.mean([h for _, _, h in covers.values()], axis=0)

    # Pass 2: hand out one distinct ramp hue per album.
    hue_prefs, hue_strength = {}, {}
    for key, name, *_ in ALBUMS:
        _, _, hist = covers[key]
        hue_prefs[name] = distinctive_hues(hist, background)
        lift = (hist + 1e-4) / (background + 1e-4)
        hue_strength[name] = float(lift.max())
    ramp_hue = assign_ramp_hues(hue_prefs, hue_strength)

    # Pass 3: derive the palettes.
    div_pairs: list[tuple[float, float]] = []
    for key, name, title, year, blurb in ALBUMS:
        lab, weight, hist = covers[key]
        hues = distinctive_hues(hist, background)

        seed = seed_qualitative(lab, weight, N_QUAL)
        qual_lab = order_qualitative(refine_qualitative(seed))
        qual = [rgb_to_hex(c) for c in lab_to_rgb(qual_lab)]

        seq = build_sequential(lab, weight, N_SEQ, hues, ramp_hue[name])
        div = build_diverging(N_DIV, hues, ramp_hue[name], div_pairs)

        palettes[name] = {
            "album": title, "year": year, "blurb": blurb,
            "qualitative": qual, "sequential": seq, "diverging": div,
        }
        qual_pool += [(name, h) for h in qual]

        de = cvd_min_distance(qual)
        ct = swatch_contrast(qual)
        report.append(
            f"{name:<14} {title:<22} min CVD dE00 {de:5.1f} "
            f"contrast>={ct['min_best_of_either']:.2f}"
        )

    # ---- greatest_hits: the most separable colours across the whole catalogue
    pool_hex = [h for _, h in qual_pool]
    pool_rgb = np.array([hex_to_rgb(h) for h in pool_hex])
    pool_lab = rgb_to_lab(pool_rgb)
    cvd_pool = _cvd_labs(pool_rgb)

    def pool_sep(i: int, j: int) -> float:
        return min(float(ciede2000(l[i], l[j])) for l in cvd_pool)

    chosen = [int(np.argmax(pool_lab[:, 1] ** 2 + pool_lab[:, 2] ** 2))]
    while len(chosen) < 12:
        nxt = max(
            (i for i in range(len(pool_hex)) if i not in chosen),
            key=lambda i: min(pool_sep(i, c) for c in chosen),
        )
        if min(pool_sep(nxt, c) for c in chosen) < 12.0:
            break
        chosen.append(nxt)
    gh = order_qualitative(pool_lab[chosen])
    gh_hex = [rgb_to_hex(c) for c in lab_to_rgb(gh)]

    gh_w = np.ones(len(pool_lab)) / len(pool_lab)
    gh_hues = distinctive_hues(hue_histogram(pool_lab, gh_w), background)
    palettes["greatest_hits"] = {
        "album": "Greatest Hits", "year": 1981,
        "blurb": "The most separable colours from all fifteen studio covers.",
        "qualitative": gh_hex,
        "sequential": build_sequential(pool_lab, gh_w, N_SEQ, gh_hues, gh_hues[0]),
        "diverging": build_diverging(N_DIV, gh_hues, gh_hues[0], div_pairs),
    }
    report.append(
        f"{'greatest_hits':<14} {'Greatest Hits':<22} min CVD dE00 "
        f"{cvd_min_distance(gh_hex):5.1f} "
        f"contrast>={swatch_contrast(gh_hex)['min_best_of_either']:.2f}"
    )

    with open(os.path.join(HERE, "palettes.json"), "w") as fh:
        json.dump(palettes, fh, indent=2)

    write_r(palettes)
    print("\n".join(report), file=sys.stderr)
    print(f"\n{len(palettes)} palette families -> {3 * len(palettes)} palettes",
          file=sys.stderr)


def write_r(palettes: dict[str, dict]) -> None:
    """Emit R/palettes-generated.R (sourced at build time, not at run time)."""
    lines = [
        "# Generated by data-raw/build_palettes.py -- DO NOT EDIT BY HAND.",
        "# Re-create with `make palettes`. Colours are derived from the Queen studio",
        "# album covers; `vignette(\"killerPals\")` documents the derivation and the",
        "# accessibility report. Documentation for this object lives in R/data.R.",
        "",
        "killer_palettes <- list(",
    ]
    entries = []
    for name, p in palettes.items():
        def vec(key: str) -> str:
            return ", ".join(f'"{h}"' for h in p[key])
        entries.append(
            f"  {name} = list(\n"
            f'    album = "{p["album"]}",\n'
            f"    year = {p['year']}L,\n"
            f'    blurb = "{p["blurb"]}",\n'
            f"    qualitative = c({vec('qualitative')}),\n"
            f"    sequential = c({vec('sequential')}),\n"
            f"    diverging = c({vec('diverging')})\n"
            f"  )"
        )
    lines.append(",\n".join(entries))
    lines.append(")")
    lines.append("")
    with open(os.path.join(HERE, "palettes-generated.R"), "w") as fh:
        fh.write("\n".join(lines))


if __name__ == "__main__":
    main()
