# IPinfo Developer Documentation - Reference

*Shared for reference. IPinfo provides geolocation and IP intelligence services that can be used with the Football Tactics Analytics Engine backend for country detection.*

---

## 📋 IPinfo API Overview

IPinfo offers geolocation and IP intelligence services that can be used with the backend's country detection endpoint (`/api/v1/country/detect`).

### 🔑 Authentication

Your API token is used to authenticate with the IPinfo API. It can be passed via:

- **Query parameter**: `?token=$TOKEN`
- **HTTP Basic Authentication**: `curl -u $TOKEN:`
- **Bearer token**: `Authorization: Bearer $TOKEN`

**Get your token**: https://dash.cloudflare.com/cloudflare-one/connections/tunnels or https://ipinfo.io/dashboard/token

---

## �iervie API Tiers

### IPinfo Lite (Free)
- **URL**: `https://api.ipinfo.io/lite/`
- **Endpoint**: `/lite`
- **Features**: Country and ASN information
- **Quota**: Unlimited access
- **Example**:
  ```bash
  curl https://api.ipinfo.io/lite/me?token=$TOKEN
  ```

### IPinfo Core (Entry-level Premium)
- **URL**: `https://api.ipinfo.io/lookup/`
- **Endpoint**: `/lookup`
- **Features**: Granular geolocation, ASN data, network flags
- **Example Response**:
  ```json
  {
    "ip": "8.8.8.8",
    "hostname": "dns.google",
    "geo": {
      "city": "Mountain View",
      "region": "California",
      "country": "United States"
    },
    "as": {
      "asn": "AS15169",
      "name": "Google LLC"
    }
  }
  ```

### IPinfo Plus
- **Features**: Accuracy radius, mobile carrier details, anonymous IP detection
- **Example Response**: Includes `radius`, `dma_code`, `geoname_id`

### IPinfo Max
- **Features**: Residential proxy detection, detailed mobile carrier info
- **Example Response**: Includes `is_res_proxy`, `last_seen`, `percent_days_seen`

---

## 📡 IP Address Parameter

The API supports:
- Specific IP: `https://api.ipinfo.io/lite/8.8.8.8?token=$TOKEN`
- Your IP: `https://api.ipinfo.io/lite/me?token=$TOKEN`
- IPv6: `https://api.ipinfo.io/lite/2001:4860:4860::8888?token=$TOKEN`
- Field filtering: `/country`, `/asn`, `/city`, etc.

---

## ⚙️ Rate Limits

- **IPinfo Lite**: Unlimited access (no daily/hourly caps)
- **Paid plans**: Monthly request limit with configurable alerts
- **429 status**: Exceeded plan limit (with metered billing, continues via overages)

**Not limited**: concurrent requests, per-second throttling on paid plans

---

## 🛠️ Usage with Football Tactics Engine

### Current Backend Configuration (`backend/app/core/config.py`):

```python
IPINFO_TOKEN: str = Field(default="", env="IPINFO_TOKEN")
```

### Geo-IP Endpoint (`backend/app/main.py`):

```python
@app.get("/api/v1/country/detect", tags=["geo"])
async def detect_country_endpoint(request: Request):
    """Detect user's country via Geo-IP."""
    client_ip = request.client.host
    country = detect_country(client_ip)
    return {"country": country, "country_code": country.upper()[:2]}
```

The `detect_country()` function uses the `IPINFO_TOKEN` environment variable. If empty (`""`), it may fall back to hardcoded country lists.

### .env Configuration (Current):

```env
IPINFO_TOKEN=your_ipinfo_token_here  # Optional - set if using Geo-IP detection
```

---

## 🎯 How to Obtain an IPinfo Token

1. **Go to**: https://ipinfo.io/dashboard/token
2. **Sign up** for a free account (or log in)
3. **Generate token** - available on the dashboard
4. **Free tier**: IPinfo Lite with unlimited access
5. **Paid tiers**: Core, Plus, Max with additional features

### After Obtaining Token:

Update your `.env` file:

```env
IPINFO_TOKEN=your_actual_ipinfo_token_here
```

Then restart the backend:

```cmd
cd D:\football-tactics-app
docker-compose restart backend
```

### Impact on Application:

- **If IPINFO_TOKEN set**: Geo-IP detection works, returns actual country based on client IP
- **If IPINFO_TOKEN empty**: Falls back to `ALLOWED_COUNTRIES` list in config (currently: Egypt, England, Spain, Italy)
- **Either way**: App continues to function - Geo-IP is an enhancement, not required

---

## 📊 IPinfo API Endpoints Summary

| Tier | URL | Endpoint | Features | Quota |
|------|-----|----------|----------|-------|
| **Lite** | `api.ipinfo.io` | `/lite` | Country + ASN | Unlimited |
| **Core** | `api.ipinfo.io` | `/lookup` | Geolocation + ASN | Monthly limit |
| **Plus** | `api.ipinfo.io` | `/lookup` | + Accuracy radius, carrier | Monthly limit |
| **Max** | `api.ipinfo.io` | `/lookup` | + Proxy detection, mobile | Monthly limit |

---

## 🔧 Integration Examples

### cURL Examples

```bash
# Lite - get own IP details
curl https://api.ipinfo.io/lite/me?token=$TOKEN

# Lite - get specific IP
curl https://api.ipinfo.io/lite/8.8.8.8?token=$TOKEN

# Lite - get country code only
curl https://api.ipinfo.io/lite/8.8.8.8/country_code?token=$TOKEN

# Lookup - full geolocation
curl https://api.ipinfo.io/lookup/8.8.8.8?token=$TOKEN

# Lookup - city only
curl https://api.ipinfo.io/lookup/8.8.8.8/geo/city?token=$TOKEN
```

### JavaScript (Fetch API)

```javascript
// Get user's country via IPinfo
async function getUserCountry() {
  const response = await fetch(
    "https://api.ipinfo.io/lite/me?token=" + YOUR_TOKEN
  );
  const data = await response.json();
  return data.country;  // Returns e.g., "United States" or "EG"
}
```

### Python (Requests)

```python
import requests

def get_ip_info(token):
    response = requests.get(
        "https://api.ipinfo.io/lite/me",
        params={"token": token}
    )
    return response.json()
```

---

## ⚠️ Important Notes for Your Project

1. **Optional Feature**: IPinfo Geo-IP detection is **optional** - the app works without it
2. **Fallback Behavior**: If no token or empty, backend uses hardcoded `ALLOWED_COUNTRIES` [England, Spain, Italy, Egypt]
3. **Client IP**: The endpoint uses `request.client.host` - works within Docker network
4. **Token Security**: Keep `.env` secure (already protected by `.dockerignore`)
5. **Rate Limits**: Lite tier = unlimited; paid tiers have monthly limits

---

## 📝 Next Steps (If You Want to Enable Geo-IP)

1. **Visit**: https://ipinfo.io/dashboard/token
2. **Create free account** → Generate Lite token
3. **Update `.env`**: `IPINFO_TOKEN=your_generated_token`
4. **Restart backend**: `docker-compose restart backend`
5. **Test**: Make requests from different IPs to see country detection

---

*Documentation shared for reference. The Football Tactics Analytics Engine functional without IPinfo - it's an optional enhancement for automatic country detection.*