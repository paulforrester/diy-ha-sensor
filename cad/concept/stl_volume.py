"""Print the enclosed volume (mm^3) of an ASCII or binary STL, by the divergence theorem."""
import struct
import sys


def triangles(path):
    data = open(path, "rb").read()
    if data[:5] == b"solid" and b"facet" in data[:400]:
        pts = [tuple(map(float, line.split()[1:4])) for line in data.decode().splitlines()
               if line.strip().startswith("vertex")]
        return [pts[i:i + 3] for i in range(0, len(pts), 3)]
    n = struct.unpack("<I", data[80:84])[0]
    out = []
    for i in range(n):
        v = struct.unpack("<12f", data[84 + 50 * i: 84 + 50 * i + 48])
        out.append([v[3:6], v[6:9], v[9:12]])
    return out


vol = 0.0
for a, b, c in triangles(sys.argv[1]):
    vol += (a[0] * (b[1] * c[2] - b[2] * c[1]) - a[1] * (b[0] * c[2] - b[2] * c[0])
            + a[2] * (b[0] * c[1] - b[1] * c[0])) / 6.0
print(f"{vol:.3f}")
