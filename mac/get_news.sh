#!/bin/bash

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
        *)
            echo "Unknown parameter: $1"
            exit 1
            ;;
    esac
done

# Check if API key is set
if [ -z "$NEWS_API_KEY" ]; then
    echo "Error: NEWS_API_KEY environment variable is not set"
    exit 1
fi

# Valid categories
valid_categories=("business" "entertainment" "general" "health" "science" "sports" "technology")

# Check if category is valid
if [[ ! " ${valid_categories[@]} " =~ " ${category} " ]]; then
    echo "Error: Invalid category. Available categories: ${valid_categories[@]}"
    exit 1
fi

# Fetch news
response=$(curl -s "https://newsapi.org/v2/top-headlines?country=us&category=$category&pageSize=$articles&apiKey=$NEWS_API_KEY")

# Check if curl request was successful
if [ $? -ne 0 ]; then
    echo "Error: Failed to fetch news"
    exit 1
fi

# Print news articles
echo -e "\nTop $articles news articles in category: $category\n"

echo "$response" | jq -r '.articles[] | "\033[33mTitle:\033[0m \(.title)\n\033[36mSource:\033[0m \(.source.name)\n\033[36mDescription:\033[0m \(.description)\n\033[36mURL:\033[0m \(.url)\n\n-------------------\n"'