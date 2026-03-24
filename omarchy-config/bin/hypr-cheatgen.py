#!/usr/bin/env python3
"""
Hyprland keybind cheat sheet generator.

Reads live bindings via `hyprctl binds -j` and outputs:
  - ASCII table (for terminal display with `less`)
  - Markdown table
  - PDF (landscape, via python-reportlab)

Usage:
  hypr-cheatgen.py --format ascii --width 80 --out /path/to/output.txt
  hypr-cheatgen.py --format md --out /path/to/output.md
  hypr-cheatgen.py --format ascii --width 80 --out out.txt --pdf out.pdf --pdf-font-size 15

Requirements:
  - hyprctl (from Hyprland)
  - python-reportlab (for PDF output): sudo pacman -S python-reportlab
"""

import argparse
import json
import subprocess
import textwrap
from collections import defaultdict

# Hyprland modmask bits: 64=SUPER, 8=ALT, 4=CTRL, 1=SHIFT
MOD_BITS = [
    (64, "SUPER"),
    (8,  "ALT"),
    (4,  "CTRL"),
    (1,  "SHIFT"),
]

# Optional: common X11 keycode mapping (works on typical US layouts)
X11_KEYCODE_MAP = {
    10: "1", 11: "2", 12: "3", 13: "4", 14: "5", 15: "6", 16: "7", 17: "8", 18: "9", 19: "0",
    24: "Q", 25: "W", 26: "E", 27: "R", 28: "T", 29: "Y", 30: "U", 31: "I", 32: "O", 33: "P",
    38: "A", 39: "S", 40: "D", 41: "F", 42: "G", 43: "H", 44: "J", 45: "K", 46: "L",
    52: "Z", 53: "X", 54: "C", 55: "V", 56: "B", 57: "N", 58: "M",
    65: "SPACE", 36: "RETURN", 22: "BACKSPACE", 9: "ESCAPE", 23: "TAB",
    107: "PRINT", 119: "DELETE",
}


def run(cmd: list[str]) -> str:
    return subprocess.check_output(cmd, text=True)


def decode_modmask(modmask) -> str:
    """Decode a numeric modmask into a human-readable string like 'SUPER + SHIFT'."""
    try:
        m = int(modmask)
    except Exception:
        return str(modmask).strip()

    names = [name for bit, name in MOD_BITS if (m & bit)]
    return " + ".join(names)


def key_from_bind(b: dict) -> str:
    """Extract a printable key name from a bind dict (handles multiple Hypr versions)."""
    k = b.get("key")
    if k and str(k).strip():
        return str(k).strip()

    kc = b.get("keycode")
    if kc is not None:
        try:
            kc_i = int(kc)
            return X11_KEYCODE_MAP.get(kc_i, f"code:{kc_i}")
        except Exception:
            pass

    code = b.get("code")
    if code is not None:
        return f"code:{code}"

    return ""


def friendly_action(b: dict) -> str:
    disp = (b.get("dispatcher") or "").strip()
    arg  = (b.get("arg") or "").strip()
    return f"{disp} {arg}".strip()


def combo_string(b: dict) -> str:
    mods = b.get("mod")
    if not mods:
        mods = b.get("modmask", "")
    mods_s = decode_modmask(mods) if mods != "" else ""
    key = key_from_bind(b)

    if mods_s and key:
        return f"{mods_s} + {key}"
    if mods_s and not key:
        return mods_s
    return key


def to_ascii_sections(binds: list[dict], width: int = 80) -> str:
    """Produce an aligned ASCII cheat sheet with fixed-width key column."""
    groups = defaultdict(list)
    for b in binds:
        disp = (b.get("dispatcher") or "unknown").strip()
        groups[disp].append((combo_string(b), friendly_action(b)))

    out = []
    for disp in sorted(groups.keys()):
        out.append(f"[{disp.upper()}]")
        rows = sorted(groups[disp], key=lambda x: (x[0], x[1]))

        key_w = 26
        act_w = max(10, width - (key_w + 3))  # " | "

        for keys, action in rows:
            keys = (keys or "").strip()
            action = (action or "").strip()

            keys_lines = textwrap.wrap(keys, width=key_w) or [""]
            act_lines  = textwrap.wrap(action, width=act_w) or [""]

            n = max(len(keys_lines), len(act_lines))
            keys_lines += [""] * (n - len(keys_lines))
            act_lines  += [""] * (n - len(act_lines))

            for i in range(n):
                out.append(f"{keys_lines[i]:<{key_w}} | {act_lines[i]}")

        out.append("")  # blank line between sections

    return "\n".join(out).rstrip() + "\n"


def to_markdown(binds: list[dict]) -> str:
    groups = defaultdict(list)
    for b in binds:
        disp = (b.get("dispatcher") or "unknown").strip()
        groups[disp].append((combo_string(b), friendly_action(b)))

    md = ["# Hyprland Keybinds Cheat Sheet\n"]
    for disp in sorted(groups.keys()):
        md.append(f"## {disp}\n")
        md.append("| Keys | Action |")
        md.append("|---|---|")
        for keys, action in sorted(groups[disp], key=lambda x: (x[0], x[1])):
            md.append(f"| {keys} | {action} |")
        md.append("")
    return "\n".join(md)


def write_pdf_ascii(content: str, pdf_path: str, *, font_size: int = 10, line_h: int = 11):
    """Render ASCII content to a landscape PDF using ReportLab."""
    try:
        import reportlab  # noqa: F401
    except ModuleNotFoundError:
        raise SystemExit("PDF generation needs ReportLab. Install: sudo pacman -S python-reportlab")

    from reportlab.pdfgen import canvas
    from reportlab.lib.pagesizes import letter, landscape
    from reportlab.lib.units import inch
    from reportlab.pdfbase import pdfmetrics
    from reportlab.pdfbase.ttfonts import TTFont

    font = "Courier"
    try:
        pdfmetrics.registerFont(TTFont("DejaVuMono", "/usr/share/fonts/TTF/DejaVuSansMono.ttf"))
        font = "DejaVuMono"
    except Exception:
        pass  # Courier fallback is fine

    pagesize = landscape(letter)
    c = canvas.Canvas(pdf_path, pagesize=pagesize)
    w, h = pagesize

    left = 0.5 * inch
    top = h - 0.5 * inch
    bottom = 0.5 * inch

    c.setFont(font, font_size)

    y = top
    for line in content.splitlines():
        if y < bottom:
            c.showPage()
            c.setFont(font, font_size)
            y = top
        c.drawString(left, y, line)
        y -= line_h

    c.save()


def main():
    ap = argparse.ArgumentParser(description="Generate a Hyprland keybind cheat sheet.")
    ap.add_argument("--format", choices=["ascii", "md"], default="ascii")
    ap.add_argument("--width", type=int, default=80)
    ap.add_argument("--out", default=None, help="Write to a file instead of stdout")
    ap.add_argument("--pdf", default=None, help="Also generate a PDF (ASCII only; requires reportlab)")
    ap.add_argument("--pdf-font-size", type=int, default=10)
    ap.add_argument("--pdf-line-height", type=int, default=11)
    args = ap.parse_args()

    binds = json.loads(run(["hyprctl", "binds", "-j"]))

    if args.format == "ascii":
        content = to_ascii_sections(binds, width=args.width)
    else:
        content = to_markdown(binds)

    if args.out:
        with open(args.out, "w", encoding="utf-8") as f:
            f.write(content)
    else:
        print(content, end="")

    if args.pdf:
        if args.format != "ascii":
            raise SystemExit("--pdf is intended for --format ascii.")
        write_pdf_ascii(
            content,
            args.pdf,
            font_size=args.pdf_font_size,
            line_h=args.pdf_line_height,
        )


if __name__ == "__main__":
    main()
