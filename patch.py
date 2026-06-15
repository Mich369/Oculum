import sys
path = r"c:\Oculum App\oculum\lib\src\main\oculum_home_map_attachments.dart"
with open(path, "r", encoding="utf-8") as f:
    content = f.read()

content = content.replace(
"""      case 'blood_chapel':
      case 'bone_saint':
        return 'cathedral';""",
"""      case 'blood_chapel':
      case 'bone_saint':
      case 'verdigris_mourning':
        return 'cathedral';"""
)

with open(path, "w", encoding="utf-8") as f:
    f.write(content)
