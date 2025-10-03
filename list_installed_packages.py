#!/usr/bin/env python3
"""
List top-level packages you installed via APT, Snap, Pip, or Cargo,
sorted by most-recent install/upgrade time, with optional CSV/JSON output
and version inclusion.

Usage:
  python3 list_installed_packages.py --manager {apt,snap,pip,cargo,all} \
      [--format {table,csv,json}] [--tz-local] [--no-tz] [--limit N]

Examples:
  # All managers, pretty table (default)
  ./list_installed_packages.py -m all

  # CSV with versions
  ./list_installed_packages.py -m apt --format csv

  # JSON across all managers, last 50 entries
  ./list_installed_packages.py -m all --format json --limit 50

Output fields:
  NAME | VERSION | INSTALLED_AT (local time unless --no-tz) | MANAGER

Notes:
- APT "top-level" = packages marked manual (apt-mark showmanual). Install time is approximated
  from /var/lib/dpkg/info/<pkg>.list mtime (upgrade updates it too).
- Snap time is from `snap list --date`'s Installed column for current revisions.
- Pip "top-level" = `pip list --not-required` (not required by others). Install time is approximated
  by the newest mtime among the distribution's .dist-info directory and package files.
- Cargo crates are those installed via `cargo install`. Time is approximated by the mtime of binaries
  in ~/.cargo/bin (latest among a crate's bin files).

Requires: python3.8+, coreutils, apt/dpkg (for apt), snapd (for snap), pip, cargo as applicable.
"""

import argparse
import json
import os
import re
import subprocess
from datetime import datetime, timezone
from pathlib import Path
from typing import List, Tuple, Dict, Optional

try:
    # Python 3.8+
    import importlib.metadata as importlib_metadata
except Exception:  # pragma: no cover
    import importlib_metadata  # type: ignore

Row = Tuple[int, str, str, str]  # (epoch_seconds, name, version, manager)


def run(cmd: str) -> subprocess.CompletedProcess:
    return subprocess.run(
        cmd, shell=True, check=False, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True
    )


# ------------------------- A P T -------------------------------------------

def apt_rows() -> List[Row]:
    rows: List[Row] = []
    r = run("apt-mark showmanual")
    if r.returncode != 0:
        return rows
    manual = set(line.strip() for line in r.stdout.splitlines() if line.strip())

    # Build map pkg->version from dpkg-query
    r2 = run("dpkg-query -W -f='${Package}\t${Version}\n'")
    if r2.returncode != 0:
        return rows
    versions: Dict[str, str] = {}
    for line in r2.stdout.splitlines():
        if not line.strip():
            continue
        try:
            pkg, ver = line.split("\t", 1)
            versions[pkg] = ver
        except ValueError:
            continue

    top = sorted(set(versions.keys()) & manual)
    for pkg in top:
        info_file = f"/var/lib/dpkg/info/{pkg}.list"
        try:
            st = os.stat(info_file)
            ts = int(st.st_mtime)
            rows.append((ts, pkg, versions.get(pkg, ""), "apt"))
        except FileNotFoundError:
            continue
    return rows


# ------------------------- S N A P -----------------------------------------

def snap_rows() -> List[Row]:
    rows: List[Row] = []
    r = run("snap list --date")
    if r.returncode != 0:
        return rows
    lines = r.stdout.splitlines()
    if not lines:
        return rows

    header = lines[0]
    # Determine column starts
    c_name = header.find("Name")
    c_ver = header.find("Version")
    c_inst = header.find("Installed")
    if min(c_name, c_ver, c_inst) == -1:
        return rows

    for line in lines[1:]:
        if not line.strip():
            continue
        # Slice fixed-width columns by header indices
        name = line[c_name:c_ver].strip()
        version = line[c_ver:c_inst].strip()
        installed_str = line[c_inst:].strip()
        ts = parse_any_datetime_to_epoch(installed_str)
        if name and ts is not None:
            rows.append((ts, name, version, "snap"))
    return rows


def parse_any_datetime_to_epoch(s: str) -> Optional[int]:
    s = s.strip()
    fmts = [
        "%Y-%m-%d %H:%M:%S %z",
        "%Y-%m-%d %H:%M %z",
        "%Y-%m-%dT%H:%M:%S%z",
        "%Y-%m-%d",
    ]
    for fmt in fmts:
        try:
            dt = datetime.strptime(s, fmt)
            return int(dt.timestamp())
        except Exception:
            pass
    m = re.match(r"(\d{4}-\d{2}-\d{2})[ T](\d{2}:\d{2}:\d{2})", s)
    if m:
        try:
            dt = datetime.strptime(m.group(1) + " " + m.group(2), "%Y-%m-%d %H:%M:%S")
            return int(dt.replace(tzinfo=timezone.utc).timestamp())
        except Exception:
            pass
    return None


# ------------------------- P I P -------------------------------------------

def pip_rows() -> List[Row]:
    rows: List[Row] = []
    r = run("python3 -m pip list --not-required --format=json")
    if r.returncode != 0:
        return rows
    try:
        pkgs = json.loads(r.stdout)
    except json.JSONDecodeError:
        return rows

    for entry in pkgs:
        name = entry.get("name")
        version = entry.get("version", "")
        if not name:
            continue
        ts = newest_mtime_for_distribution(name)
        if ts is not None:
            rows.append((ts, name, version, "pip"))
    return rows


def normalize_dist_name(n: str) -> str:
    return re.sub(r"[-_.]+", "-", n).lower()


def newest_mtime_for_distribution(name: str) -> Optional[int]:
    target = normalize_dist_name(name)
    dist = None
    try:
        dist = importlib_metadata.distribution(name)
    except importlib_metadata.PackageNotFoundError:
        for d in importlib_metadata.distributions():
            try:
                if normalize_dist_name(d.metadata["Name"]) == target:
                    dist = d
                    break
            except Exception:
                continue
    if not dist:
        return None

    mtimes: List[int] = []
    for f in (dist.files or []):
        try:
            p = dist.locate_file(f)
            st = os.stat(p)
            mtimes.append(int(st.st_mtime))
        except Exception:
            continue
    if not mtimes:
        try:
            path = Path(dist.locate_file(".")).resolve()
            if path.exists():
                mtimes.append(int(path.stat().st_mtime))
        except Exception:
            pass
    return max(mtimes) if mtimes else None


# ------------------------- C A R G O ---------------------------------------

def cargo_rows() -> List[Row]:
    rows: List[Row] = []
    r = run("cargo install --list")
    if r.returncode != 0:
        return rows
    lines = r.stdout.splitlines()

    crate = None
    crates_to_bins: Dict[str, List[str]] = {}
    crate_versions: Dict[str, str] = {}

    for line in lines:
        if not line.strip():
            continue
        # Example: "ripgrep v14.1.0:" or "bat v0.24.0:" etc.
        m = re.match(r"^([\w\-]+) v([^:]+):", line.strip())
        if m:
            crate = m.group(1)
            ver = m.group(2)
            crate_versions[crate] = ver
            crates_to_bins.setdefault(crate, [])
            continue
        if crate and line.startswith(" "):
            b = line.strip().split()[0].strip('"')
            crates_to_bins[crate].append(b)

    cargo_bin = Path.home() / ".cargo" / "bin"
    for crate, bins in crates_to_bins.items():
        mtimes: List[int] = []
        for b in bins or [crate]:
            p = cargo_bin / b
            if p.exists():
                try:
                    mtimes.append(int(p.stat().st_mtime))
                except Exception:
                    pass
        if mtimes:
            rows.append((max(mtimes), crate, crate_versions.get(crate, ""), "cargo"))
    return rows


# ------------------------- F O R M A T S -----------------------------------

def sort_rows(rows: List[Row]) -> List[Row]:
    return sorted(rows, key=lambda r: r[0], reverse=True)


def format_table(rows: List[Row], local_tz: bool) -> str:
    rows = sort_rows(rows)
    header = f"{'NAME':40} {'VERSION':16} {'INSTALLED_AT':25} {'MANAGER'}"
    out = [header]
    for ts, name, ver, mgr in rows:
        dt = datetime.fromtimestamp(ts)
        if not local_tz:
            dt = datetime.utcfromtimestamp(ts)
        out.append(f"{name:40} {ver:16} {dt.isoformat(sep=' ', timespec='seconds'):25} {mgr}")
    return "\n".join(out)


def format_csv(rows: List[Row], local_tz: bool) -> str:
    rows = sort_rows(rows)
    out = ["NAME,VERSION,INSTALLED_AT,MANAGER"]
    for ts, name, ver, mgr in rows:
        dt = datetime.fromtimestamp(ts) if local_tz else datetime.utcfromtimestamp(ts)
        # naive CSV escaping for commas/quotes
        name_q = name.replace('"', '""')
        ver_q = ver.replace('"', '""')
        out.append(f'"{name_q}","{ver_q}","{dt.isoformat(sep=" ", timespec="seconds")}","{mgr}"')
    return "\n".join(out)


def format_json(rows: List[Row], local_tz: bool) -> str:
    rows = sort_rows(rows)
    items = []
    for ts, name, ver, mgr in rows:
        dt = datetime.fromtimestamp(ts) if local_tz else datetime.utcfromtimestamp(ts)
        items.append({
            "name": name,
            "version": ver,
            "installed_at": dt.isoformat(sep=" ", timespec="seconds"),
            "manager": mgr,
            "epoch": ts,
        })
    return json.dumps(items, indent=2)


# ---------------------------- M A I N --------------------------------------

def main():
    ap = argparse.ArgumentParser(description="List top-level installed packages by recency.")
    ap.add_argument(
        "--manager",
        "-m",
        choices=["apt", "snap", "pip", "cargo", "all"],
        default="all",
        help="Which package ecosystem to query",
    )
    ap.add_argument(
        "--format",
        "-f",
        choices=["table", "csv", "json"],
        default="table",
        help="Output format",
    )
    ap.add_argument("--limit", type=int, default=0, help="Show only the N most recent entries")
    tz = ap.add_mutually_exclusive_group()
    tz.add_argument("--tz-local", dest="local_tz", action="store_true", help="Use local time (default)")
    tz.add_argument("--no-tz", dest="local_tz", action="store_false", help="Use UTC time")
    ap.set_defaults(local_tz=True)

    args = ap.parse_args()

    all_rows: List[Row] = []
    if args.manager in ("apt", "all"):
        all_rows.extend(apt_rows())
    if args.manager in ("snap", "all"):
        all_rows.extend(snap_rows())
    if args.manager in ("pip", "all"):
        all_rows.extend(pip_rows())
    if args.manager in ("cargo", "all"):
        all_rows.extend(cargo_rows())

    # Apply limit after sorting
    all_rows = sort_rows(all_rows)
    if args.limit and args.limit > 0:
        all_rows = all_rows[: args.limit]

    if args.format == "table":
        print(format_table(all_rows, args.local_tz))
    elif args.format == "csv":
        print(format_csv(all_rows, args.local_tz))
    else:
        print(format_json(all_rows, args.local_tz))


if __name__ == "__main__":
    main()
