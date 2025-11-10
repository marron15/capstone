# RNR Fitness Gym - PWA Deployment Guide for Hostinger

This guide provides step-by-step instructions for deploying your Flutter PWA to Hostinger hosting.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Building the Flutter Web App](#building-the-flutter-web-app)
3. [Deploying to Hostinger](#deploying-to-hostinger)
4. [Enabling HTTPS](#enabling-https)
5. [Testing the PWA](#testing-the-pwa)
6. [Troubleshooting](#troubleshooting)

---

## Prerequisites

- Flutter SDK installed
- Hostinger hosting account
- FTP client (FileZilla, WinSCP, or Hostinger's File Manager)
- Basic understanding of web deployment

---

## Building the Flutter Web App

### Step 1: Build for Web

Open your terminal/command prompt and navigate to your project directory:

```bash
cd c:\xampp\htdocs\capstone
```

Build the Flutter web app with PWA support:

```bash
flutter build web --release
```

**Important:** This will create the optimized production build in the `build/web` directory.

### Step 2: Verify Build Output

Ensure the following files exist in `build/web`:
- ✅ `index.html` (with PWA code)
- ✅ `manifest.json`
- ✅ `sw.js` (service worker)
- ✅ `flutter_bootstrap.js`
- ✅ `main.dart.js`
- ✅ `icons/` folder with all icon files

---

## Deploying to Hostinger

### Option A: Using Hostinger File Manager (Recommended)

1. **Log into Hostinger**
   - Go to https://www.hostinger.com
   - Login to your account
   - Navigate to hPanel

2. **Open File Manager**
   - Click on "File Manager" in the hPanel
   - Navigate to your domain's public folder (usually `public_html`)

3. **Upload Files**
   - Delete any existing files in `public_html` (or create a backup)
   - Select all files from `build/web` (on your local machine)
   - Upload them to `public_html`
   - **Important:** Maintain the folder structure (including the `icons/` folder)

4. **Set Permissions**
   - Ensure all files have `644` permissions
   - Ensure all folders have `755` permissions

### Option B: Using FTP Client (FileZilla)

1. **Get FTP Credentials**
   - From hPanel → FTP Accounts
   - Note: FTP host, username, and password

2. **Connect via FileZilla**
   - Host: `ftp.yourdomain.com`
   - Username: Your FTP username
   - Password: Your FTP password
   - Port: 21

3. **Upload Files**
   - Connect to your server
   - Navigate to `public_html` folder
   - Delete existing files
   - Upload all files from `build/web` to `public_html`
   - Maintain folder structure

### Option C: Using Command Line (Advanced)

If you have SSH access:

```bash
# From your local machine
cd build/web
tar -czf web.tar.gz *
scp web.tar.gz username@your-server:/home/username/public_html/
ssh username@your-server
cd public_html
tar -xzf web.tar.gz
rm web.tar.gz
```

---

## Enabling HTTPS

**CRITICAL:** PWAs require HTTPS to function properly (except on localhost).

### Automatic SSL (Hostinger)

1. **Enable SSL Certificate**
   - Log into hPanel
   - Navigate to "SSL" section
   - Click on "Let's Encrypt"
   - Select your domain
   - Click "Activate"
   - Wait 5-10 minutes for activation

2. **Force HTTPS Redirect**
   - In hPanel, go to "File Manager"
   - Open or create `.htaccess` file in `public_html`
   - Add these lines:

```apache
RewriteEngine On
RewriteCond %{HTTPS} off
RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]
```

### Verify HTTPS
- Visit your site: `https://yourdomain.com`
- Check for the padlock icon in the browser
- Ensure no "Not Secure" warnings appear

---

## Testing the PWA

### 1. Check Manifest
Open browser console (F12) and navigate to:
- **Chrome DevTools:** Application → Manifest
- Verify:
  - ✅ Name: "RNR Fitness Gym"
  - ✅ Icons loading correctly
  - ✅ No errors in manifest

### 2. Check Service Worker
In Chrome DevTools → Application → Service Workers:
- ✅ Status: activated and running
- ✅ Console shows "Service Worker registered"
- No errors in Console

### 3. Test Installability

#### Desktop (Chrome/Edge):
1. Visit your site at `https://yourdomain.com`
2. Look for the **Install icon (download button)** in the header
3. Click the Install button
4. A browser popup should appear
5. Click "Install"
6. Confirm app appears in your installed apps

#### Mobile (Android Chrome):
1. Visit your site on mobile browser
2. Tap the 3-dot menu (⋮)
3. Look for "Add to Home screen" or "Install app"
4. Tap to install
5. App icon appears on home screen

#### Mobile (iOS Safari):
1. Visit your site on Safari
2. Tap Share button (square with arrow)
3. Tap "Add to Home Screen"
4. Customize if needed, then tap "Add"

### 4. Test Offline Functionality

1. Install the PWA (from step 3)
2. Open DevTools → Network
3. Check "Offline" checkbox
4. Refresh the page
5. ✅ Page should still load (cached content)
6. Navigate to different pages
7. ✅ App should work offline (cached pages)

### 5. Test Install Button
- Visit your site in a supported browser (Chrome, Edge, Samsung Internet)
- The install button should appear in the header (download icon)
- Only visible when browser supports PWA install
- Click button → Install prompt appears
- After install or dismiss → Button shows appropriate SnackBar message

---

## Testing Checklist

Use this checklist after deployment:

- [ ] **HTTPS Enabled** - URL shows `https://` and padlock icon
- [ ] **Manifest Valid** - No errors in DevTools → Application → Manifest
- [ ] **Service Worker Registered** - Running in DevTools → Application → Service Workers
- [ ] **Icons Display** - All icons load correctly (192x192, 512x512)
- [ ] **Install Button Appears** - Download icon visible in header (when browser supports install)
- [ ] **Install Works** - Clicking install button triggers browser install prompt
- [ ] **SnackBar Messages** - Success/error messages show after install attempt
- [ ] **App Installs** - App can be installed and appears in system launcher
- [ ] **Offline Works** - App loads when offline (show offline indicator)
- [ ] **No Console Errors** - Browser console shows no errors
- [ ] **Performance** - Lighthouse PWA score > 90
- [ ] **Mobile Friendly** - App works on mobile devices

---

## Troubleshooting

### Issue: Install button doesn't appear

**Causes:**
- PWA already installed on device
- Browser doesn't support PWA (use Chrome/Edge)
- Not visiting via HTTPS
- App doesn't meet PWA criteria

**Solutions:**
1. Check DevTools → Application → Manifest (no errors)
2. Verify service worker is registered
3. Ensure HTTPS is enabled
4. Test in incognito/private window
5. Check that manifest.json and sw.js are accessible

### Issue: Service Worker not registering

**Causes:**
- Files not uploaded correctly
- Wrong file permissions
- HTTPS not enabled
- CORS issues

**Solutions:**
1. Check file permissions (644 for files, 755 for folders)
2. Ensure `sw.js` exists in root directory
3. Verify HTTPS is working
4. Check browser console for errors
5. Clear browser cache and reload

### Issue: App doesn't work offline

**Causes:**
- Service worker not caching properly
- Files not in cache list

**Solutions:**
1. Check `sw.js` file is uploaded correctly
2. Verify URLs in `urlsToCache` array
3. Clear cache and reinstall
4. Check DevTools → Application → Cache Storage

### Issue: Install prompt doesn't appear

**Causes:**
- App already installed
- Browser doesn't support install prompts
- Missing PWA criteria

**Solutions:**
1. Uninstall PWA and try again
2. Use Chrome or Edge (Chromium-based)
3. Check manifest is valid
4. Ensure you've visited site before (engagement heuristic)

### Issue: SnackBar not showing

**Causes:**
- JavaScript error
- Context lost

**Solutions:**
1. Check browser console for errors
2. Ensure Flutter app fully loaded
3. Try clicking button after page fully loads

---

## Performance Optimization

After deployment, run Lighthouse audit:

1. Open Chrome DevTools (F12)
2. Go to "Lighthouse" tab
3. Check "Progressive Web App"
4. Click "Generate report"
5. Aim for score > 90

### Quick Wins:
- ✅ Ensure images are optimized
- ✅ Enable compression on server
- ✅ Use CDN for static assets
- ✅ Minimize JavaScript bundles

---

## Support

For issues specific to:
- **Flutter PWA:** Check Flutter web documentation
- **Hostinger:** Contact Hostinger support
- **PWA Standards:** Check MDN PWA documentation

---

## Files Overview

Your PWA consists of these key files:

```
public_html/
├── index.html              # Main HTML with PWA logic
├── manifest.json           # PWA manifest
├── sw.js                   # Service worker
├── main.dart.js            # Compiled Flutter app
├── flutter_bootstrap.js     # Flutter bootstrap
├── icons/                  # App icons
│   ├── Icon-192.png
│   ├── Icon-512.png
│   └── Icon-maskable-*.png
└── assets/                # App assets
```

---

## Next Steps

1. ✅ Deploy to Hostinger
2. ✅ Enable HTTPS
3. ✅ Test all features
4. ✅ Monitor analytics
5. ✅ Gather user feedback
6. ✅ Update content as needed

---

**Congratulations!** Your Flutter PWA is now deployed and ready for users to install! 🎉

