import re

file_path = r'd:\phe_flutter\lib\core\constants\dispur_wss_components.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Check for specification field
for i, line in enumerate(lines):
    if 'specification:' in line:
        print(f"ERROR: Found 'specification' at line {i+1}: {line.strip()}")

# Check IDs and Categories
ids_per_category = {}
current_category = None
errors = []

# Crude parsing of the list
inside_list = False
current_item = {}

for i, line in enumerate(lines):
    if 'wtpComponents = [' in line:
        inside_list = True
        continue
    if '];' in line and inside_list:
        inside_list = False
        continue
    
    if inside_list:
        # Match fields
        id_match = re.search(r'id:\s*(\d+)', line)
        cat_match = re.search(r'category:\s*"(.*?)"', line)
        
        if id_match:
            current_item['id'] = int(id_match.group(1))
        if cat_match:
            current_item['category'] = cat_match.group(1)
            
        if '),' in line: # End of an item
            if 'id' in current_item and 'category' in current_item:
                cat = current_item['category']
                cid = current_item['id']
                
                if cat not in ids_per_category:
                    ids_per_category[cat] = set()
                
                if cid in ids_per_category[cat]:
                    errors.append(f"Line {i+1}: Duplicate ID {cid} in category '{cat}'")
                
                ids_per_category[cat].add(cid)
            current_item = {}

if errors:
    print("\n".join(errors))
else:
    print("No obvious duplicate ID errors found.")
