import os
import tempfile

_TMP_DIR = tempfile.mkdtemp(prefix="saiydd-tests-")
os.environ["DATABASE_URL"] = (
    f"sqlite:///{_TMP_DIR}/test.db".replace("\\", "/")
)
