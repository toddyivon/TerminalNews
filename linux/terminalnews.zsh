#!/usr/bin/env zsh

# Default values
category="general"
articles=5

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--category)
            category="$2"
            shift 2
            ;;
        -n|--number)
            articles="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: terminalnews [options]"
            echo "Options:"
            echo "  -c, --category <category>  News category (default: general)"
            echo "                            Available: business, entertainment, general,"
            echo "                            health, science, sports, technology"
            echo "  -n, --number <number>     Number of articles to display (default: 5)"
            echo "  -h, --help               Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown parameter: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

# Check if API key is set
if [[ -z "$NEWS_API_KEY" ]]; then
    echo "Error: NEWS_API_KEY environment variable is not set"
    echo "Add this to your ~/.zshrc file:"
    echo 'export NEWS_API_KEY="your_api_key"'
    echo ""
    echo "Or set it temporarily with:"
    echo 'export NEWS_API_KEY="your_api_key"'
    exit 1
fi

# Valid categories as an array
valid_categories=(business entertainment general health science sports technology)

# Check if category is valid using zsh array membership test
if ! (( ${valid_categories[(Ie)$category]} )); then
    echo "Error: Invalid category '$category'"
    echo "Available categories: ${(j:, :)valid_categories}"
    exit 1
fi

# Fetch news
print -P "%F{cyan}Fetching news...%f"
response=$(curl -s "https://newsapi.org/v2/top-headlines?country=us&category=$category&pageSize=$articles&apiKey=$NEWS_API_KEY")

# Check if curl request was successful
if [[ $? -ne 0 ]]; then
    echo "Error: Failed to fetch news"
    exit 1
fi

# Print header
print -P "\n%B%F{green}═══ Top $articles news articles in category: $category ═══%f%b\n"

# Use jq with simple formatting (avoiding control character issues)
echo "$response" | jq -r --arg n "$articles" '
    if .status == "ok" then
        (.articles[:($n | tonumber)] | to_entries[] | 
        "\n📰 \(.value.title // "No title")\n" +
        "   Source: \(.value.source.name // "Unknown")\n" +
        "   \(.value.description // "No description" | .[0:200])\n" +
        "   🔗 \(.value.url // "")\n" +
        "   ─────────────────────────────────────────────────────────")
    else
        "Error: \(.message // "Unknown error")"
    end
' 2>/dev/null || {
    # Fallback to Python if jq fails
    echo "$response" | python3 -c "
import sys, json, re

try:
    # Read and clean input
    content = sys.stdin.read()
    # Remove problematic control characters
    content = ''.join(char if ord(char) >= 32 or char in '\\n\\t' else ' ' for char in content)
    
    data = json.loads(content)
    
    if data.get('status') != 'ok':
        print(f\"Error: {data.get('message', 'Unknown error')}\")
        sys.exit(1)
    
    articles = data.get('articles', [])[:$articles]
    
    for i, article in enumerate(articles, 1):
        title = article.get('title', 'No title')
        source = article.get('source', {}).get('name', 'Unknown')
        desc = article.get('description', 'No description')[:200]
        url = article.get('url', 'No URL')
        
        print(f\"\\n📰 {title}\")
        print(f\"   Source: {source}\")
        print(f\"   {desc}\")
        print(f\"   🔗 {url}\")
        print(\"   \" + \"─\" * 53)
    
    print(f\"\\n   Total available: {data.get('totalResults', 0)} articles\")
    
except Exception as e:
    print(f\"Error processing response: {e}\")
    sys.exit(1)
"
}

print -P "\n%F{cyan}═══════════════════════════════════════════════════════%f"