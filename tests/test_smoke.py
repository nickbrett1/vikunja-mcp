"""Smoke test: the src-layout package installs and imports cleanly."""


def test_package_imports():
    import vikunja_mcp

    assert vikunja_mcp.__version__
