"""Colour-science helpers used to derive the killerPals palettes.

Implements sRGB <-> CIELAB conversion, the Machado, Oliveira & Fernandes (2009)
colour-vision-deficiency simulation matrices, CIEDE2000 colour difference and
WCAG relative-luminance contrast.  Kept dependency-light (numpy only) so the
palette derivation in `build_palettes.py` is fully reproducible.
"""

from __future__ import annotations

import numpy as np

# ---------------------------------------------------------------- sRGB <-> Lab

_M_RGB2XYZ = np.array(
    [
        [0.4124564, 0.3575761, 0.1804375],
        [0.2126729, 0.7151522, 0.0721750],
        [0.0193339, 0.1191920, 0.9503041],
    ]
)
_M_XYZ2RGB = np.linalg.inv(_M_RGB2XYZ)
_D65 = np.array([0.95047, 1.00000, 1.08883])


def srgb_to_linear(rgb: np.ndarray) -> np.ndarray:
    rgb = np.asarray(rgb, dtype=float)
    return np.where(rgb <= 0.04045, rgb / 12.92, ((rgb + 0.055) / 1.055) ** 2.4)


def linear_to_srgb(lin: np.ndarray) -> np.ndarray:
    lin = np.clip(np.asarray(lin, dtype=float), 0.0, 1.0)
    return np.where(lin <= 0.0031308, lin * 12.92, 1.055 * lin ** (1 / 2.4) - 0.055)


def rgb_to_lab(rgb: np.ndarray) -> np.ndarray:
    """rgb in [0, 1], shape (..., 3) -> CIELAB (D65)."""
    xyz = srgb_to_linear(rgb) @ _M_RGB2XYZ.T / _D65
    eps, kappa = 216 / 24389, 24389 / 27
    f = np.where(xyz > eps, np.cbrt(xyz), (kappa * xyz + 16) / 116)
    fx, fy, fz = f[..., 0], f[..., 1], f[..., 2]
    return np.stack([116 * fy - 16, 500 * (fx - fy), 200 * (fy - fz)], axis=-1)


def lab_to_rgb(lab: np.ndarray) -> np.ndarray:
    """CIELAB (D65) -> sRGB in [0, 1], clipped to gamut."""
    lab = np.asarray(lab, dtype=float)
    L, a, b = lab[..., 0], lab[..., 1], lab[..., 2]
    fy = (L + 16) / 116
    fx, fz = fy + a / 500, fy - b / 200
    eps3, kappa = (216 / 24389), 24389 / 27
    f = np.stack([fx, fy, fz], axis=-1)
    xyz = np.where(f**3 > eps3, f**3, (116 * f - 16) / kappa)
    return np.clip(linear_to_srgb((xyz * _D65) @ _M_XYZ2RGB.T), 0.0, 1.0)


# --------------------------------------------------------------------- hex I/O


def hex_to_rgb(h: str) -> np.ndarray:
    h = h.lstrip("#")
    return np.array([int(h[i : i + 2], 16) for i in (0, 2, 4)], dtype=float) / 255.0


def rgb_to_hex(rgb: np.ndarray) -> str:
    v = np.clip(np.asarray(rgb, dtype=float), 0, 1) * 255
    return "#{:02X}{:02X}{:02X}".format(*(int(round(c)) for c in v))


# ------------------------------------------------- colour-vision deficiency

# Machado, Oliveira & Fernandes (2009), severity 1.0, applied in linear RGB.
CVD_MATRICES = {
    "protan": np.array(
        [
            [0.152286, 1.052583, -0.204868],
            [0.114503, 0.786281, 0.099216],
            [-0.003882, -0.048116, 1.051998],
        ]
    ),
    "deutan": np.array(
        [
            [0.367322, 0.860646, -0.227968],
            [0.280085, 0.672501, 0.047413],
            [-0.011820, 0.042940, 0.968881],
        ]
    ),
    "tritan": np.array(
        [
            [1.255528, -0.076749, -0.178779],
            [-0.078411, 0.930809, 0.147602],
            [0.004733, 0.691367, 0.303900],
        ]
    ),
}
CVD_TYPES = ("normal", "deutan", "protan", "tritan")


def simulate_cvd(rgb: np.ndarray, kind: str) -> np.ndarray:
    """Simulate dichromatic vision for sRGB values in [0, 1]."""
    if kind == "normal":
        return np.asarray(rgb, dtype=float)
    lin = srgb_to_linear(rgb) @ CVD_MATRICES[kind].T
    return linear_to_srgb(lin)


# ----------------------------------------------------------------- CIEDE2000


def ciede2000(lab1: np.ndarray, lab2: np.ndarray) -> np.ndarray:
    """CIEDE2000 colour difference between two broadcastable Lab arrays."""
    L1, a1, b1 = lab1[..., 0], lab1[..., 1], lab1[..., 2]
    L2, a2, b2 = lab2[..., 0], lab2[..., 1], lab2[..., 2]

    C1, C2 = np.hypot(a1, b1), np.hypot(a2, b2)
    Cbar = (C1 + C2) / 2
    G = 0.5 * (1 - np.sqrt(Cbar**7 / (Cbar**7 + 25.0**7 + 1e-12)))
    a1p, a2p = (1 + G) * a1, (1 + G) * a2
    C1p, C2p = np.hypot(a1p, b1), np.hypot(a2p, b2)

    h1p = np.degrees(np.arctan2(b1, a1p)) % 360
    h2p = np.degrees(np.arctan2(b2, a2p)) % 360

    dLp = L2 - L1
    dCp = C2p - C1p
    dhp = h2p - h1p
    dhp = np.where(dhp > 180, dhp - 360, np.where(dhp < -180, dhp + 360, dhp))
    dhp = np.where(C1p * C2p == 0, 0.0, dhp)
    dHp = 2 * np.sqrt(C1p * C2p) * np.sin(np.radians(dhp) / 2)

    Lbarp = (L1 + L2) / 2
    Cbarp = (C1p + C2p) / 2
    hsum, hdiff = h1p + h2p, np.abs(h1p - h2p)
    hbarp = np.where(
        C1p * C2p == 0,
        hsum,
        np.where(
            hdiff <= 180,
            hsum / 2,
            np.where(hsum < 360, (hsum + 360) / 2, (hsum - 360) / 2),
        ),
    )

    T = (
        1
        - 0.17 * np.cos(np.radians(hbarp - 30))
        + 0.24 * np.cos(np.radians(2 * hbarp))
        + 0.32 * np.cos(np.radians(3 * hbarp + 6))
        - 0.20 * np.cos(np.radians(4 * hbarp - 63))
    )
    dtheta = 30 * np.exp(-(((hbarp - 275) / 25) ** 2))
    Rc = 2 * np.sqrt(Cbarp**7 / (Cbarp**7 + 25.0**7 + 1e-12))
    Sl = 1 + (0.015 * (Lbarp - 50) ** 2) / np.sqrt(20 + (Lbarp - 50) ** 2)
    Sc = 1 + 0.045 * Cbarp
    Sh = 1 + 0.015 * Cbarp * T
    Rt = -np.sin(np.radians(2 * dtheta)) * Rc

    return np.sqrt(
        (dLp / Sl) ** 2
        + (dCp / Sc) ** 2
        + (dHp / Sh) ** 2
        + Rt * (dCp / Sc) * (dHp / Sh)
    )


# ------------------------------------------------------------- WCAG contrast


def relative_luminance(rgb: np.ndarray) -> np.ndarray:
    lin = srgb_to_linear(rgb)
    return lin @ np.array([0.2126, 0.7152, 0.0722])


def contrast_ratio(rgb1: np.ndarray, rgb2: np.ndarray) -> np.ndarray:
    l1, l2 = relative_luminance(rgb1), relative_luminance(rgb2)
    lo, hi = np.minimum(l1, l2), np.maximum(l1, l2)
    return (hi + 0.05) / (lo + 0.05)


WHITE = np.array([1.0, 1.0, 1.0])
BLACK = np.array([0.0, 0.0, 0.0])


def cvd_min_distance(hexes: list[str]) -> float:
    """Worst-case pairwise CIEDE2000 across normal and all three CVD types."""
    rgb = np.array([hex_to_rgb(h) for h in hexes])
    worst = np.inf
    for kind in CVD_TYPES:
        lab = rgb_to_lab(simulate_cvd(rgb, kind))
        d = ciede2000(lab[:, None, :], lab[None, :, :])
        np.fill_diagonal(d, np.inf)
        worst = min(worst, float(d.min()))
    return worst


def swatch_contrast(hexes: list[str]) -> dict[str, float]:
    """Best achievable contrast of each swatch against white / black text."""
    rgb = np.array([hex_to_rgb(h) for h in hexes])
    return {
        "min_vs_white": float(contrast_ratio(rgb, WHITE).min()),
        "min_vs_black": float(contrast_ratio(rgb, BLACK).min()),
        "min_best_of_either": float(
            np.maximum(contrast_ratio(rgb, WHITE), contrast_ratio(rgb, BLACK)).min()
        ),
    }
