import base64
import sys

def convert_to_base64(font_path):
    with open(font_path, 'rb') as font_file:
        encoded = base64.b64encode(font_file.read()).decode('utf-8')
    return encoded

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: python convert_font_to_base64.py <font_path>")
        sys.exit(1)
    
    font_path = sys.argv[1]
    base64_string = convert_to_base64(font_path)
    
    # Print to stdout for capture
    print(base64_string)
