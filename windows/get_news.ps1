# PowerShell Script for Windows

param (
    [string]$category = "general",
    [int]$articles = 5
)

$apiKey = $env:NEWS_API_KEY
if (-not $apiKey) {
    Write-Host "Error: NEWS_API_KEY environment variable is not set" -ForegroundColor Red
    exit 1
}

$categories = @("business", "entertainment", "general", "health", "science", "sports", "technology")
if ($category -notin $categories) {
    Write-Host "Error: Invalid category. Available categories: $($categories -join ', ')" -ForegroundColor Red
    exit 1
}

$url = "https://newsapi.org/v2/top-headlines?country=us&category=$category&pageSize=$articles&apiKey=$apiKey"

try {
    $response = Invoke-RestMethod -Uri $url -Method Get
    
    Write-Host "`nTop $articles news articles in category: $category`n" -ForegroundColor Cyan
    
    foreach ($article in $response.articles) {
        Write-Host "Title: $($article.title)" -ForegroundColor Yellow
        Write-Host "Source: $($article.source.name)"
        Write-Host "Description: $($article.description)"
        Write-Host "URL: $($article.url)"
        Write-Host "-" * 80 -ForegroundColor Gray
        Write-Host ""
    }
} catch {
    Write-Host "Error fetching news: $_" -ForegroundColor Red
}