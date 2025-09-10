import importlib
import pkgutil

NODE_CLASS_MAPPINGS = {}

# 自动扫描当前目录下所有 .py 文件（排除 __init__.py 本身）
for module_info in pkgutil.iter_modules(__path__):
    module_name = module_info.name
    if module_name == "__init__":
        continue

    module = importlib.import_module(f"{__name__}.{module_name}")
    if hasattr(module, "NODE_CLASS_MAPPINGS"):
        NODE_CLASS_MAPPINGS.update(module.NODE_CLASS_MAPPINGS)
