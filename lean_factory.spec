# PyInstaller spec — builds lean_factory.exe
# Run: pyinstaller lean_factory.spec
# Output: dist/lean_factory/lean_factory.exe

block_cipher = None

a = Analysis(
    ['main.py'],
    pathex=['.'],
    binaries=[],
    datas=[
        ('data/*.yaml',   'data'),
        ('assets/sprites/*', 'assets/sprites'),
        ('assets/tilesets/*', 'assets/tilesets'),
        ('assets/sounds/*',   'assets/sounds'),
    ],
    hiddenimports=[
        'pygame',
        'pygame_gui',
        'anthropic',
        'yaml',
        'sqlite3',
    ],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
    noarchive=False,
)

pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

exe = EXE(
    pyz,
    a.scripts,
    [],
    exclude_binaries=True,
    name='lean_factory',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    console=False,   # Set to True for headless/debug mode
    disable_windowed_traceback=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
    icon=None,       # Add 'assets/icon.ico' when available
)

coll = COLLECT(
    exe,
    a.binaries,
    a.zipfiles,
    a.datas,
    strip=False,
    upx=True,
    upx_exclude=[],
    name='lean_factory',
)
