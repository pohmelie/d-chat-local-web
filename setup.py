from cx_Freeze import setup, Executable


options = {
    "build_exe": {
        "create_shared_zip": False,
    }
}

executables = [
    Executable(
        script="d-chat-web.py",
        targetName="d-chat-local-web.exe",
        compress=True,
        copyDependentFiles=True,
        appendScriptToExe=True,
        appendScriptToLibrary=False,
        icon="d-chat-web.ico",
    )
]

setup(
    name="d-chat-local-web",
    version="0.0.1",
    description="",
    options=options,
    executables=executables,
)
