import re


class LooseVersion:
    """
    Minimal drop-in replacement for distutils.version.LooseVersion,
    which was removed from the standard library in Python 3.12.
    """

    _component_re = re.compile(r"(\d+|[a-zA-Z]+|\.)")

    def __init__(self, vstring):
        self.vstring = vstring
        self.version = self._parse(vstring)

    def _parse(self, vstring):
        components = [c for c in self._component_re.split(vstring) if c and c != "."]
        parts = []
        for c in components:
            try:
                parts.append(int(c))
            except ValueError:
                parts.append(c)
        return parts

    def __str__(self):
        return self.vstring

    def __repr__(self):
        return "LooseVersion('{0}')".format(self.vstring)

    def _compare(self, other):
        if isinstance(other, str):
            other = LooseVersion(other)
        a, b = self.version, other.version
        length = max(len(a), len(b))
        a = a + [0] * (length - len(a))
        b = b + [0] * (length - len(b))
        for x, y in zip(a, b):
            if type(x) is not type(y):
                x, y = str(x), str(y)
            if x < y:
                return -1
            if x > y:
                return 1
        return 0

    def __eq__(self, other):
        return self._compare(other) == 0

    def __ne__(self, other):
        return self._compare(other) != 0

    def __lt__(self, other):
        return self._compare(other) < 0

    def __le__(self, other):
        return self._compare(other) <= 0

    def __gt__(self, other):
        return self._compare(other) > 0

    def __ge__(self, other):
        return self._compare(other) >= 0


# StrictVersion enforces an X.Y.Z-ish format in distutils; for our purposes
# (simple >= comparisons against reported tool/library versions) the looser
# parser behaves the same, so we reuse it here as well.
StrictVersion = LooseVersion


_versionstring = "1.2.124"
looseversion = LooseVersion(_versionstring)
openwebrx_version = "v{0}".format(looseversion)
