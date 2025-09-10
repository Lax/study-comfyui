class ShowTextNode:
    @classmethod
    def INPUT_TYPES(cls):
        return {
            "required": {
                "text": ("STRING", {
                    "multiline": True,
                    "default": "[Open console to see output]"
                })
            }
        }

    RETURN_TYPES = ("STRING",)
    RETURN_NAMES = ("text",)
    FUNCTION = "show_text"
    CATEGORY = "Utils"

    def show_text(self, text):
        # 在后台日志里也打印一下
        print(f"[ShowTextNode] {text}")
        # 返回给工作流，可以继续传递下去
        return (text,)


NODE_CLASS_MAPPINGS = {
    "ShowText": ShowTextNode
}

NODE_DISPLAY_NAME_MAPPINGS = {
    "ShowText": "📝 Show Text"
}
