# Quick Start - Deploy PWA to Hostinger

## 🚀 Quick Deployment Steps

### 1. Build Your App

```bash
cd c:\xampp\htdocs\capstone
flutter clean
flutter build web --release
```

### 2. Upload to Hostinger

**Option A: File Manager (Easiest)**
1. Login to Hostinger hPanel
2. Go to File Manager
3. Navigate to `public_html`
4. Upload ALL files from `build/web/`

**Option B: FTP (FileZilla)**
1. Connect to `ftp.yourdomain.com`
2. Go to `public_html`
3. Upload ALL files from `build/web/`

### 3. Enable HTTPS (REQUIRED)

1. hPanel → SSL → Let's Encrypt → Activate
2. Wait 5-10 minutes
3. Visit your site with `https://`

### 4. Test Installation

1. Visit your site
2. Look for download icon in header (top right)
3. Click icon → Install app
4. Verify SnackBar message appears

## ✅ Done!

Your PWA is now live. Users can:
- Install the app from their browser
- Use it offline
- Get native app experience

## 📋 Quick Verification

Visit: `https://yourdomain.com`
- [ ] Install button appears in header
- [ ] Click button → Install prompt shows
- [ ] App installs successfully
- [ ] No console errors

## 🐛 Common Issues

**Install button doesn't show?**
- Try incognito/private mode
- Clear browser cache
- Check browser supports PWA (Chrome/Edge)

**HTTPS issues?**
- Wait for SSL to activate (5-10 min)
- Ensure .htaccess forces HTTPS
- Clear browser cache

**Service worker errors?**
- Verify all files uploaded correctly
- Check file permissions (644/755)
- Clear browser cache

## 📚 Full Documentation

- **Deployment Guide**: `DEPLOYMENT_GUIDE.md`
- **Setup Summary**: `PWA_SETUP_SUMMARY.md`
- **This File**: Quick reference

## 💡 Pro Tips

1. **Test locally first**: Run `flutter run -d chrome` before deploying
2. **Check Lighthouse**: DevTools → Lighthouse → PWA audit
3. **Monitor Analytics**: Track installs and usage
4. **Update Cache**: Change cache version in `sw.js` when updating content

---

**Need Help?** See `DEPLOYMENT_GUIDE.md` for detailed instructions.

