#!/usr/bin/env python3
"""Regenerate project.pbxproj file references from the .swift files on disk.

Run after adding, moving, or deleting Swift files:
    python3 scripts/sync_project.py
Folders under lightLiteroom/ become Xcode groups with matching paths.
"""
import hashlib
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "lightLiteroom")
PBX = os.path.join(ROOT, "lightLiteroom.xcodeproj", "project.pbxproj")

MAIN_GROUP = "678B30FAF98DABE79481BF94"
SRC_GROUP = "908CE232B31CDB20C3D2C330"
PRODUCTS_GROUP = "A0AA5AED9517D111D5B59539"
APP_REF = "160403660171653E2A419F33"
ASSETS_REF = "D7F39220FC6CFD38BAC84F6F"
ASSETS_BUILD = "A1AEC887CEA7758618DD2339"


def uid(key):
    return hashlib.md5(key.encode()).hexdigest()[:24].upper()


swift = []
for dirpath, dirnames, filenames in os.walk(SRC):
    dirnames[:] = sorted(d for d in dirnames if not d.endswith(".xcassets"))
    for name in sorted(filenames):
        if name.endswith(".swift"):
            swift.append(os.path.relpath(os.path.join(dirpath, name), SRC))

build_files = [
    f"\t\t{uid('build:' + p)} /* {os.path.basename(p)} in Sources */ = "
    f"{{isa = PBXBuildFile; fileRef = {uid('ref:' + p)} /* {os.path.basename(p)} */; }};"
    for p in swift
] + [
    f"\t\t{ASSETS_BUILD} /* Assets.xcassets in Resources */ = "
    f"{{isa = PBXBuildFile; fileRef = {ASSETS_REF} /* Assets.xcassets */; }};"
]

file_refs = [
    f"\t\t{uid('ref:' + p)} /* {os.path.basename(p)} */ = {{isa = PBXFileReference; "
    f"lastKnownFileType = sourcecode.swift; path = \"{os.path.basename(p)}\"; sourceTree = \"<group>\"; }};"
    for p in swift
] + [
    f"\t\t{ASSETS_REF} /* Assets.xcassets */ = {{isa = PBXFileReference; "
    f"lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = \"<group>\"; }};",
    f"\t\t{APP_REF} /* lightLiteroom.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; "
    f"includeInIndex = 0; path = lightLiteroom.app; sourceTree = BUILT_PRODUCTS_DIR; }};",
]

groups = {}  # relative dir -> [(child id, child comment)]


def group_id(d):
    return SRC_GROUP if d == "" else uid("group:" + d)


def ensure(d):
    if d in groups:
        return
    groups[d] = []
    if d:
        parent = os.path.dirname(d)
        ensure(parent)
        groups[parent].append((group_id(d), os.path.basename(d)))


ensure("")
for p in swift:
    ensure(os.path.dirname(p))
    groups[os.path.dirname(p)].append((uid("ref:" + p), os.path.basename(p)))
groups[""].append((ASSETS_REF, "Assets.xcassets"))


def group_block(gid, comment, children, path=None, name=None):
    head = f"\t\t{gid} /* {comment} */ = {{" if comment else f"\t\t{gid} = {{"
    lines = [head, "\t\t\tisa = PBXGroup;", "\t\t\tchildren = ("]
    lines += [f"\t\t\t\t{cid} /* {c} */," for cid, c in children]
    lines.append("\t\t\t);")
    if name:
        lines.append(f"\t\t\tname = {name};")
    if path:
        lines.append(f"\t\t\tpath = {path};")
    lines += ["\t\t\tsourceTree = \"<group>\";", "\t\t};"]
    return "\n".join(lines)


group_blocks = [group_block(MAIN_GROUP, None, [(SRC_GROUP, "lightLiteroom"), (PRODUCTS_GROUP, "Products")])]
for d in sorted(groups):
    label = "lightLiteroom" if d == "" else os.path.basename(d)
    group_blocks.append(group_block(group_id(d), label, groups[d], path=label))
group_blocks.append(group_block(PRODUCTS_GROUP, "Products", [(APP_REF, "lightLiteroom.app")], name="Products"))

sources = [f"\t\t\t\t{uid('build:' + p)} /* {os.path.basename(p)} in Sources */," for p in swift]


def replace_section(text, section, body):
    pattern = rf"(/\* Begin {section} section \*/\n).*?(/\* End {section} section \*/)"
    return re.sub(pattern, lambda m: m.group(1) + body + "\n" + m.group(2), text, flags=re.S)


with open(PBX) as f:
    text = f.read()
text = replace_section(text, "PBXBuildFile", "\n".join(build_files))
text = replace_section(text, "PBXFileReference", "\n".join(file_refs))
text = replace_section(text, "PBXGroup", "\n".join(group_blocks))
text = re.sub(
    r"(isa = PBXSourcesBuildPhase;\n\t\t\tbuildActionMask = \d+;\n\t\t\tfiles = \(\n).*?(\t\t\t\);)",
    lambda m: m.group(1) + "\n".join(sources) + "\n" + m.group(2),
    text,
    flags=re.S,
)
with open(PBX, "w") as f:
    f.write(text)
print(f"synced {len(swift)} swift files into {os.path.relpath(PBX, ROOT)}")
