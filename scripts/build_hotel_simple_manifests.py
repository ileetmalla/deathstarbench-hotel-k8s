#!/usr/bin/env python3
from pathlib import Path
import re

SRC = Path("hotelReservation/kubernetes")
DST = Path("hotelReservation/kubernetes-simple")

if not SRC.exists():
    raise SystemExit(f"ERROR: source folder not found: {SRC}")

if DST.exists():
    for p in DST.glob("*.yaml"):
        p.unlink()
else:
    DST.mkdir(parents=True, exist_ok=True)

groups = [
    ("01-consul.yaml", "consul"),
    ("02-jaeger.yaml", "jaeger"),
    ("10-frontend.yaml", "frontend"),
    ("20-geo.yaml", "geo"),
    ("30-profile.yaml", "profile"),
    ("40-rate.yaml", "rate"),
    ("50-recommendation.yaml", "reccomend"),
    ("60-reservation.yaml", "reserve"),
    ("70-search.yaml", "search"),
    ("80-user.yaml", "user"),
]

pinned_deployments = {
    "mongodb-geo",
    "mongodb-profile",
    "mongodb-rate",
    "mongodb-recommendation",
    "mongodb-reservation",
    "mongodb-user",
    "memcached-profile",
    "memcached-rate",
    "memcached-reserve",
}

pvc_to_pv = {
    "geo-pvc": "geo-pv",
    "profile-pvc": "profile-pv",
    "rate-pvc": "rate-pv",
    "recommendation-pvc": "recommendation-pv",
    "reservation-pvc": "reservation-pv",
    "user-pvc": "user-pv",
}

command_replacements = {
    "./frontend": "/go/bin/frontend",
    "./geo": "/go/bin/geo",
    "./profile": "/go/bin/profile",
    "./rate": "/go/bin/rate",
    "./recommendation": "/go/bin/recommendation",
    "./reservation": "/go/bin/reservation",
    "./search": "/go/bin/search",
    "./user": "/go/bin/user",
}

cluster_scoped_kinds = {
    "Namespace",
    "PersistentVolume",
    "StorageClass",
    "ClusterRole",
    "ClusterRoleBinding",
    "CustomResourceDefinition",
}

def split_docs(text):
    return [d.strip() for d in re.split(r"(?m)^---\s*$", text) if d.strip()]

def get_kind(doc):
    m = re.search(r"(?m)^kind:\s*([A-Za-z0-9]+)\s*$", doc)
    return m.group(1) if m else None

def get_name(doc):
    lines = doc.splitlines()
    in_metadata = False

    for line in lines:
        if line.startswith("metadata:"):
            in_metadata = True
            continue

        if in_metadata:
            if line.startswith("  name:"):
                return line.split(":", 1)[1].strip().strip('"').strip("'")
            if line and not line.startswith(" "):
                break

    return None

def add_namespace(doc, kind):
    if kind in cluster_scoped_kinds:
        return doc

    if "namespace: hotel-res" in doc:
        return doc

    lines = doc.splitlines()
    out = []
    in_metadata = False
    inserted = False

    for line in lines:
        out.append(line)

        if line.startswith("metadata:"):
            in_metadata = True
            continue

        if in_metadata and line.startswith("  name:") and not inserted:
            out.append("  namespace: hotel-res")
            inserted = True
            in_metadata = False

    return "\n".join(out)

def fix_commands(doc):
    for old, new in command_replacements.items():
        doc = doc.replace(old, new)
    return doc

def pin_deployment(doc, kind, name):
    if kind != "Deployment" or name not in pinned_deployments:
        return doc

    if "kubernetes.io/hostname: im-hp-10" in doc:
        return doc

    block = """      nodeSelector:
        kubernetes.io/hostname: im-hp-10
      tolerations:
        - key: node-role.kubernetes.io/control-plane
          operator: Exists
          effect: NoSchedule
        - key: node-role.kubernetes.io/master
          operator: Exists
          effect: NoSchedule
"""

    if "      containers:" not in doc:
        raise RuntimeError(f"Could not find containers block for Deployment/{name}")

    return doc.replace("      containers:", block + "      containers:", 1)

def pin_pv(doc, kind):
    if kind != "PersistentVolume":
        return doc

    if "kubernetes.io/hostname: im-hp-10" in doc:
        return doc

    affinity = """spec:
  nodeAffinity:
    required:
      nodeSelectorTerms:
        - matchExpressions:
            - key: kubernetes.io/hostname
              operator: In
              values:
                - im-hp-10
"""

    return doc.replace("spec:\n", affinity, 1)

def bind_pvc(doc, kind, name):
    if kind != "PersistentVolumeClaim":
        return doc

    if name not in pvc_to_pv:
        return doc

    if "volumeName:" in doc:
        return doc

    pv = pvc_to_pv[name]
    return doc.replace("spec:\n", f"spec:\n  volumeName: {pv}\n", 1)

def transform(doc):
    kind = get_kind(doc)
    name = get_name(doc)

    if not kind:
        return doc.strip()

    doc = fix_commands(doc)
    doc = add_namespace(doc, kind)

    if name:
        doc = pin_deployment(doc, kind, name)
        doc = bind_pvc(doc, kind, name)

    doc = pin_pv(doc, kind)

    return doc.strip()

# Namespace
(DST / "00-namespace.yaml").write_text("""apiVersion: v1
kind: Namespace
metadata:
  name: hotel-res
""")

# Service group files
for output_file, folder in groups:
    folder_path = SRC / folder

    if not folder_path.exists():
        raise SystemExit(f"ERROR: missing upstream folder: {folder_path}")

    docs = []

    for path in sorted(folder_path.glob("*.y*ml")):
        for doc in split_docs(path.read_text()):
            docs.append(transform(doc))

    (DST / output_file).write_text("\n---\n".join(docs) + "\n")

print(f"Created simple manifests in {DST}")
