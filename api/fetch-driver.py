"""Extract the Playwright driver from the official playwright wheel (sha256-checked)."""
import hashlib, os, stat, urllib.request, zipfile
url, want = os.environ["PW_WHEEL_URL"], os.environ["PW_WHEEL_SHA256"]
urllib.request.urlretrieve(url, "/tmp/pw.whl")
got = hashlib.sha256(open("/tmp/pw.whl", "rb").read()).hexdigest()
assert got == want, f"playwright wheel sha256 {got} != {want}"
out = "/driver/1.57.0"
with zipfile.ZipFile("/tmp/pw.whl") as z:
    for info in z.infolist():
        if not info.filename.startswith("playwright/driver/") or info.is_dir():
            continue
        dest = os.path.join(out, info.filename[len("playwright/driver/"):])
        os.makedirs(os.path.dirname(dest), exist_ok=True)
        with z.open(info) as src, open(dest, "wb") as dst:
            dst.write(src.read())
        mode = (info.external_attr >> 16) & 0o777
        os.chmod(dest, mode or 0o644)
os.chmod(os.path.join(out, "node"), 0o755)
