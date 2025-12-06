# Backend Connection Test Script

Write-Host "🔍 Checking Backend Connection..." -ForegroundColor Cyan
Write-Host ""

$backendUrl = "http://localhost:3000"
$apiUrl = "$backendUrl/api/products"

# Test 1: Check if backend is running
Write-Host "Test 1: Checking if backend is running at $backendUrl" -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri $backendUrl -TimeoutSec 5 -ErrorAction Stop
    Write-Host "✅ Backend is running!" -ForegroundColor Green
    Write-Host "   Status: $($response.StatusCode)" -ForegroundColor Gray
} catch {
    Write-Host "❌ Backend is NOT running!" -ForegroundColor Red
    Write-Host "   Please start backend with: cd Back-End-Web; npm start" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# Test 2: Check products API
Write-Host "Test 2: Testing Products API at $apiUrl" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri $apiUrl -Method Get -TimeoutSec 5 -ErrorAction Stop
    
    if ($response.success -eq $true) {
        Write-Host "✅ Products API is working!" -ForegroundColor Green
        
        if ($response.data.products) {
            $productCount = $response.data.products.Count
            Write-Host "   Found $productCount products" -ForegroundColor Gray
            
            if ($productCount -gt 0) {
                $firstProduct = $response.data.products[0]
                Write-Host "   Sample product: $($firstProduct.name)" -ForegroundColor Gray
            }
        } elseif ($response.data -is [Array]) {
            $productCount = $response.data.Count
            Write-Host "   Found $productCount products" -ForegroundColor Gray
        }
    } else {
        Write-Host "⚠️  API returned success=false" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Products API failed!" -ForegroundColor Red
    Write-Host "   Error: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Test 3: Check auth API
$loginUrl = "$backendUrl/api/auth/login"
Write-Host "Test 3: Testing Auth API at $loginUrl" -ForegroundColor Yellow
try {
    $body = @{
        username = "test"
        password = "wrongpassword"
    } | ConvertTo-Json
    
    $response = Invoke-RestMethod -Uri $loginUrl -Method Post -Body $body -ContentType "application/json" -TimeoutSec 5 -ErrorAction SilentlyContinue
    
    # Even if login fails, API is responsive
    Write-Host "✅ Auth API is responsive!" -ForegroundColor Green
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    if ($statusCode -eq 401) {
        Write-Host "✅ Auth API is working (401 expected for wrong credentials)" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Auth API returned status: $statusCode" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "🎉 Backend health check completed!" -ForegroundColor Cyan
Write-Host ""
Write-Host "📱 Next steps:" -ForegroundColor Yellow
Write-Host "   1. Update api_config.dart with your IP address" -ForegroundColor Gray
Write-Host "   2. Run: flutter run" -ForegroundColor Gray
Write-Host "   3. Test login with real credentials from your database" -ForegroundColor Gray
