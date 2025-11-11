
import os
import re

def extract_links_outside_code_blocks(content):
    """Extract markdown links, excluding those in code blocks."""
    lines = content.split('\n')
    in_code_block = False
    links = []

    for line in lines:
        # Toggle code block state
        if line.strip().startswith('```') or line.strip().startswith('~~~'):
            in_code_block = not in_code_block
            continue

        # Only process links outside code blocks
        if not in_code_block:
            # Find all markdown links [text](url)
            matches = re.findall(r'\[([^\]]*)\]\(([^)]*)\)', line)
            for text, url in matches:
                links.append(url)

    return links

def check_links(directory):
    broken_links = []
    for root, _, files in os.walk(directory):
        for file in files:
            if file.endswith(".md"):
                filepath = os.path.join(root, file)
                with open(filepath, "r") as f:
                    content = f.read()
                    links = extract_links_outside_code_blocks(content)
                    for link in links:
                        # Skip external URLs, mailto links, and pure anchors
                        if link.startswith("http") or link.startswith("mailto") or link.startswith("#"):
                            continue

                        # Strip anchor from link (e.g., "file.md#section" -> "file.md")
                        link_without_anchor = link.split('#')[0]

                        # Skip if it's just an anchor (empty after stripping)
                        if not link_without_anchor:
                            continue

                        # Resolve path relative to the markdown file
                        link_path = os.path.join(os.path.dirname(filepath), link_without_anchor)
                        link_path = os.path.normpath(link_path)

                        # Check if file or directory exists
                        if not os.path.exists(link_path):
                            broken_links.append((filepath, link))
    return broken_links

if __name__ == "__main__":
    broken = check_links("docs")
    if broken:
        for link in broken:
            print(f"Broken link in {link[0]}: {link[1]}")
        exit(1)
    else:
        print("No broken links found.")
